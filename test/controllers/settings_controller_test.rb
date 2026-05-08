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
end
