require "test_helper"
require "webauthn/fake_client"

class PasskeyRegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = WebAuthn::FakeClient.new("http://www.example.com")
  end

  test "GET new returns options naming the account being created" do
    get new_passkey_registration_url, params: { display_name: "newclimber" }

    assert_response :success
    options = JSON.parse(response.body)
    assert_equal "newclimber", options["user"]["name"]
    assert_equal "www.example.com", options["rp"]["id"]

    pending = session[:pending_passkey_registration]
    assert_equal "newclimber", pending["display_name"]
    assert_equal options["challenge"], pending["challenge"]
    assert_equal options["user"]["id"], pending["webauthn_id"]
  end

  test "GET new normalizes the display name" do
    get new_passkey_registration_url, params: { display_name: "  NewClimber  " }

    assert_response :success
    assert_equal "newclimber", JSON.parse(response.body)["user"]["name"]
  end

  test "GET new refuses a taken display name before any prompt is shown" do
    get new_passkey_registration_url, params: { display_name: users(:one).display_name }

    assert_response :unprocessable_entity
    assert_equal "Display name has already been taken", JSON.parse(response.body)["error"]
    assert_nil session[:pending_passkey_registration]
  end

  test "GET new refuses an invalid display name" do
    get new_passkey_registration_url, params: { display_name: "no spaces!" }

    assert_response :unprocessable_entity
    assert_match(/lowercase letters/, JSON.parse(response.body)["error"])
  end

  test "GET new refuses a blank display name" do
    get new_passkey_registration_url, params: { display_name: "" }

    assert_response :unprocessable_entity
    assert_nil session[:pending_passkey_registration]
  end

  test "POST create makes an account with no email and signs it in" do
    credential = start_signup("newclimber")

    assert_difference [ "User.count", "Passkey.count" ], 1 do
      post passkey_registration_url, params: { credential: credential.to_json }
    end

    user = User.find_by(display_name: "newclimber")
    assert_nil user.email
    assert_equal 1, user.passkeys.count
    assert_redirected_to root_path

    get settings_url
    assert_response :success
  end

  test "POST create leaves no account behind when the attestation does not verify" do
    get new_passkey_registration_url, params: { display_name: "newclimber" }
    stray = WebAuthn::Credential.options_for_create(user: { id: "x", name: "x" }).challenge

    assert_no_difference "User.count" do
      post passkey_registration_url,
        params: { credential: @client.create(challenge: stray, user_verified: true).to_json }
    end

    assert_redirected_to new_user_registration_path
    assert_equal "That passkey could not be verified. Please try again.", flash[:alert]
  end

  test "POST create rejects a credential the user never verified themselves" do
    credential = start_signup("newclimber", user_verified: false)

    assert_no_difference "User.count" do
      post passkey_registration_url, params: { credential: credential.to_json }
    end
    assert_redirected_to new_user_registration_path
  end

  test "POST create without a pending sign-up is refused" do
    assert_no_difference "User.count" do
      post passkey_registration_url, params: { credential: "{}" }
    end

    assert_redirected_to new_user_registration_path
    assert_equal "That sign-up expired. Please try again.", flash[:alert]
  end

  test "POST create cannot be replayed to make a second account" do
    credential = start_signup("newclimber")
    post passkey_registration_url, params: { credential: credential.to_json }

    assert_no_difference "User.count" do
      post passkey_registration_url, params: { credential: credential.to_json }
    end
  end

  test "a passkey account can sign in afterwards" do
    post passkey_registration_url, params: { credential: start_signup("newclimber").to_json }
    user = User.find_by(display_name: "newclimber")
    sign_out user

    get new_passkey_session_url
    challenge = JSON.parse(response.body)["challenge"]
    assertion = @client.get(
      challenge: challenge,
      user_verified: true,
      user_handle: WebAuthn.standard_encoder.decode(user.webauthn_id)
    )
    post passkey_session_url, params: { credential: assertion.to_json }

    assert_redirected_to root_path
    get settings_url
    assert_response :success
  end

  test "the sign-up page offers the passkey ceremony" do
    get new_user_registration_url

    assert_response :success
    assert_select "form[action=?][data-controller='passkey'][data-passkey-options-url-value=?]",
      passkey_registration_path, new_passkey_registration_path
    assert_select "input[name='display_name'][data-passkey-target='name']"
    assert_select "button[data-action='passkey#register']"
  end

  private

  def start_signup(display_name, user_verified: true)
    get new_passkey_registration_url, params: { display_name: display_name }
    challenge = JSON.parse(response.body)["challenge"]
    @client.create(challenge: challenge, user_verified: user_verified)
  end
end
