require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "oauth-999",
      info: { email: "linked@example.com" }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
    Rails.application.env_config.delete("omniauth.auth")
  end

  test "callback signs up a new account when nobody is signed in" do
    assert_difference "User.count", 1 do
      post user_google_oauth2_omniauth_callback_path
    end
    assert User.exists?(provider: "google_oauth2", uid: "oauth-999")
  end

  test "callback links the identity to the signed-in account instead of creating one" do
    user = users(:one)
    sign_in user

    assert_no_difference "User.count" do
      post user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to settings_path
    user.reload
    assert_equal "google_oauth2", user.provider
    assert_equal "oauth-999", user.uid
  end

  test "callback merges the duplicate account the identity already created" do
    duplicate = User.from_omniauth(OmniAuth.config.mock_auth[:google_oauth2])
    user = users(:one)
    sign_in user

    assert_difference "User.count", -1 do
      post user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to settings_path
    assert_equal "oauth-999", user.reload.uid
    assert_not User.exists?(duplicate.id)
  end

  test "callback refuses a second identity for an already-linked account" do
    user = users(:one)
    user.update!(provider: "entra_id", uid: "azure-1")
    sign_in user

    post user_google_oauth2_omniauth_callback_path

    assert_redirected_to settings_path
    assert_equal "entra_id", user.reload.provider
  end
end
