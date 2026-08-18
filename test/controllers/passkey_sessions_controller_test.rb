require "test_helper"
require "webauthn/fake_client"

class PasskeySessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = WebAuthn::FakeClient.new("http://www.example.com")
    @passkey = register_passkey
  end

  test "GET new returns request options without naming the user" do
    get new_passkey_session_url

    assert_response :success
    options = JSON.parse(response.body)
    assert_equal "www.example.com", options["rpId"]
    assert_equal "required", options["userVerification"]
    assert_empty options["allowCredentials"]
    assert_nil options["user"]
    assert_equal options["challenge"], session[:passkey_authentication_challenge]
  end

  test "POST create signs the user in" do
    post passkey_session_url, params: { credential: assertion.to_json }

    assert_redirected_to root_path

    # Reaching an authenticated page is the real proof the session was created.
    get settings_url
    assert_response :success
  end

  test "POST create records the passkey as used" do
    assert_nil @passkey.last_used_at

    freeze_time do
      post passkey_session_url, params: { credential: assertion.to_json }

      @passkey.reload
      assert_equal Time.current, @passkey.last_used_at
    end
  end

  test "POST create consumes the challenge so an assertion cannot be replayed" do
    credential = assertion
    post passkey_session_url, params: { credential: credential.to_json }
    assert_nil session[:passkey_authentication_challenge]

    sign_out @user
    post passkey_session_url, params: { credential: credential.to_json }

    assert_redirected_to new_user_session_path
    assert_equal "That sign-in expired. Please try again.", flash[:alert]
  end

  test "POST create rejects an assertion signed for a different challenge" do
    fetch_challenge
    stray = WebAuthn::Credential.options_for_get.challenge

    post passkey_session_url, params: { credential: @client.get(challenge: stray, user_verified: true).to_json }

    assert_redirected_to new_user_session_path
    assert_equal "That passkey could not be verified. Please try again.", flash[:alert]
  end

  test "POST create rejects a credential the user never verified themselves" do
    post passkey_session_url, params: { credential: assertion(user_verified: false).to_json }

    assert_redirected_to new_user_session_path
    assert_equal "That passkey could not be verified. Please try again.", flash[:alert]
  end

  test "POST create rejects a passkey that is no longer registered" do
    credential = assertion
    @passkey.destroy

    post passkey_session_url, params: { credential: credential.to_json }

    assert_redirected_to new_user_session_path
    assert_equal "That passkey is not registered here.", flash[:alert]
  end

  test "POST create rejects an assertion reporting a different account" do
    post passkey_session_url,
      params: { credential: assertion(user_handle: users(:two).webauthn_handle).to_json }

    assert_redirected_to new_user_session_path
    assert_equal "That passkey could not be verified.", flash[:alert]
  end

  test "the sign-in page offers the passkey ceremony" do
    get new_user_session_url

    assert_response :success
    assert_select "form[action=?][data-controller='passkey'][data-passkey-options-url-value=?]",
      passkey_session_path, new_passkey_session_path
    assert_select "button[data-action='passkey#authenticate']"
  end

  private

  # Runs the real registration ceremony so the stored public key actually
  # matches the fake authenticator's private one.
  def register_passkey
    sign_in @user
    get new_passkey_url
    challenge = JSON.parse(response.body)["challenge"]
    post passkeys_url, params: { credential: @client.create(challenge: challenge, user_verified: true).to_json }
    sign_out @user
    @user.passkeys.sole
  end

  def fetch_challenge
    get new_passkey_session_url
    JSON.parse(response.body)["challenge"]
  end

  def assertion(user_verified: true, user_handle: @user.webauthn_id)
    @client.get(
      challenge: fetch_challenge,
      user_verified: user_verified,
      user_handle: WebAuthn.standard_encoder.decode(user_handle)
    )
  end
end
