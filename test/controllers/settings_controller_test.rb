require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "GET index requires authentication" do
    get settings_url
    assert_redirected_to new_user_session_path
  end

  test "GET index renders integrations including theCrag and UKC" do
    sign_in @user
    get settings_url
    assert_response :success
    assert_select "form[action=?]", sync_thecrag_crag_ascent_imports_path
    assert_select "form[action=?]", sync_ukc_crag_ascent_imports_path
  end

  test "GET index prefills saved theCrag and UKC identifiers" do
    @user.update!(thecrag_username: "alice", ukc_user_id: "12345")
    sign_in @user
    get settings_url
    assert_response :success
    assert_select "input[name='thecrag_username'][value=?]", "alice"
    assert_select "input[name='ukc_user_id'][value=?]", "12345"
  end

  # The key field is a password input, so it can never be prefilled; the badge
  # and the removal checkbox are the only signs that a key is saved at all.
  test "GET index offers to remove a saved theCrag API key" do
    @user.update!(thecrag_username: "alice", thecrag_api_key: "secret-key")
    sign_in @user
    get settings_url
    assert_response :success
    assert_select "input[name='thecrag_api_key'][value=?]", ""
    assert_select "input[name='remove_thecrag_api_key']"
    assert_select "body", text: /API key saved/
  end

  test "GET index does not offer removal when no key is saved" do
    @user.update!(thecrag_username: "alice", thecrag_api_key: nil)
    sign_in @user
    get settings_url
    assert_response :success
    assert_select "input[name='remove_thecrag_api_key']", false
  end

  test "GET index warns when a passkey would die with its device" do
    @user.passkeys.create!(external_id: SecureRandom.uuid, public_key: SecureRandom.uuid,
      nickname: "Yubikey", backup_eligible: false, backed_up: false)
    sign_in @user
    get settings_url

    assert_response :success
    assert_match "This device only", response.body
    assert_match(/None of your passkeys sync/, response.body)
  end

  test "GET index does not nag when every passkey is synced" do
    @user.passkeys.create!(external_id: SecureRandom.uuid, public_key: SecureRandom.uuid,
      nickname: "Dashlane", backup_eligible: true, backed_up: true)
    sign_in @user
    get settings_url

    assert_response :success
    assert_match "Synced", response.body
    assert_no_match(/None of your passkeys sync/, response.body)
  end

  test "GET index does not nag when a synced passkey covers a device-bound one" do
    @user.passkeys.create!(external_id: SecureRandom.uuid, public_key: SecureRandom.uuid,
      nickname: "Yubikey", backup_eligible: false, backed_up: false)
    @user.passkeys.create!(external_id: SecureRandom.uuid, public_key: SecureRandom.uuid,
      nickname: "iCloud", backup_eligible: true, backed_up: true)
    sign_in @user
    get settings_url

    assert_response :success
    assert_no_match(/None of your passkeys sync/, response.body)
  end

  test "GET index lists passkeys and offers to add one" do
    @user.passkeys.create!(external_id: SecureRandom.uuid, public_key: SecureRandom.uuid, nickname: "Pixel")
    sign_in @user
    get settings_url

    assert_response :success
    assert_select "form[action=?][data-controller='passkey'][data-passkey-options-url-value=?]",
      passkeys_path, new_passkey_path
    assert_select "input[type='hidden'][name='credential'][data-passkey-target='credential']"
    assert_select "button[data-passkey-target='submit'][data-action='passkey#register'][type='button']"
    assert_select "p[data-passkey-target='error'][hidden]"
    assert_select "form[action=?]", passkey_path(@user.passkeys.first)
    assert_match "Pixel", response.body
  end
end
