require "test_helper"
require "webauthn/fake_client"

class PasskeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = WebAuthn::FakeClient.new("http://www.example.com")
  end

  test "GET new requires authentication" do
    get new_passkey_url
    assert_redirected_to new_user_session_path
  end

  test "GET new returns creation options and holds the challenge server-side" do
    sign_in @user
    get new_passkey_url

    assert_response :success
    options = JSON.parse(response.body)
    assert_equal "www.example.com", options["rp"]["id"]
    assert_equal @user.reload.webauthn_id, options["user"]["id"]
    assert_equal options["challenge"], session[:passkey_challenge]
  end

  test "GET new excludes passkeys already registered to the account" do
    existing = register_passkey
    sign_in @user
    get new_passkey_url

    excluded = JSON.parse(response.body)["excludeCredentials"].map { |c| c["id"] }
    assert_equal [ existing.external_id ], excluded
  end

  test "POST create registers a passkey" do
    sign_in @user
    challenge = fetch_challenge
    credential = @client.create(challenge: challenge, user_verified: true)

    assert_difference "Passkey.count", 1 do
      post passkeys_url, params: { credential: credential.to_json, nickname: "MacBook" }
    end

    assert_redirected_to settings_path
    passkey = @user.passkeys.last
    assert_equal "MacBook", passkey.nickname
    assert_equal credential["id"], passkey.external_id
    assert passkey.public_key.present?
  end

  test "POST create records a synced credential as synced" do
    sign_in @user
    challenge = fetch_challenge
    credential = @client.create(challenge: challenge, user_verified: true,
      backup_eligibility: true, backup_state: true)

    post passkeys_url, params: { credential: credential.to_json }

    assert_equal :synced, @user.passkeys.last.storage
  end

  test "POST create records a device-bound credential as device bound" do
    sign_in @user
    challenge = fetch_challenge
    credential = @client.create(challenge: challenge, user_verified: true,
      backup_eligibility: false, backup_state: false)

    post passkeys_url, params: { credential: credential.to_json }

    passkey = @user.passkeys.last
    assert_equal :device_bound, passkey.storage
    assert passkey.device_bound?
  end

  test "POST create names the passkey when no nickname is given" do
    sign_in @user
    challenge = fetch_challenge
    credential = @client.create(challenge: challenge, user_verified: true)

    post passkeys_url, params: { credential: credential.to_json, nickname: "" }

    assert_equal "Passkey 1", @user.passkeys.last.nickname
  end

  test "POST create consumes the challenge so it cannot be replayed" do
    sign_in @user
    challenge = fetch_challenge
    credential = @client.create(challenge: challenge, user_verified: true)

    post passkeys_url, params: { credential: credential.to_json }
    assert_nil session[:passkey_challenge]

    assert_no_difference "Passkey.count" do
      post passkeys_url, params: { credential: credential.to_json }
    end
    assert_equal "That registration expired. Please try again.", flash[:alert]
  end

  test "POST create rejects an attestation signed for a different challenge" do
    sign_in @user
    fetch_challenge
    other_challenge = WebAuthn::Credential.options_for_create(user: { id: "x", name: "x" }).challenge
    credential = @client.create(challenge: other_challenge, user_verified: true)

    assert_no_difference "Passkey.count" do
      post passkeys_url, params: { credential: credential.to_json }
    end
    assert_redirected_to settings_path
    assert_equal "That passkey could not be verified. Please try again.", flash[:alert]
  end

  test "POST create rejects a credential the user never verified themselves" do
    sign_in @user
    challenge = fetch_challenge
    credential = @client.create(challenge: challenge, user_verified: false)

    assert_no_difference "Passkey.count" do
      post passkeys_url, params: { credential: credential.to_json }
    end
    assert_equal "That passkey could not be verified. Please try again.", flash[:alert]
  end

  test "POST create rejects malformed input" do
    sign_in @user
    fetch_challenge

    assert_no_difference "Passkey.count" do
      post passkeys_url, params: { credential: "not json" }
    end
    assert_redirected_to settings_path
  end

  test "DELETE destroy removes the user's own passkey" do
    passkey = register_passkey
    sign_in @user

    assert_difference "Passkey.count", -1 do
      delete passkey_url(passkey)
    end
    assert_redirected_to settings_path
  end

  test "DELETE destroy will not remove another user's passkey" do
    passkey = register_passkey(users(:two))
    sign_in @user

    assert_no_difference "Passkey.count" do
      delete passkey_url(passkey)
    end
    assert_response :not_found
  end


  # Regression: the relying party used to be hardcoded to port 3000, so a
  # ceremony served from any other port failed origin verification.
  test "registers a passkey when the app is served from a non-default port" do
    host! "localhost:3100"
    client = WebAuthn::FakeClient.new("http://localhost:3100")
    sign_in @user

    get new_passkey_url
    options = JSON.parse(response.body)
    assert_equal "localhost", options["rp"]["id"]

    credential = client.create(challenge: options["challenge"], user_verified: true)

    assert_difference "Passkey.count", 1 do
      post passkeys_url, params: { credential: credential.to_json }
    end
    assert_redirected_to settings_path
  end

  test "production pins the relying party to the canonical host" do
    assert_equal "homeboard.zone", WebAuthn.configuration.rp_id
    assert_equal [ "https://homeboard.zone" ], WebAuthn.configuration.allowed_origins
  end

  private

  # Runs the options request the browser makes first, returning the challenge
  # the fake authenticator has to sign.
  def fetch_challenge
    get new_passkey_url
    JSON.parse(response.body)["challenge"]
  end

  def register_passkey(user = @user)
    user.passkeys.create!(
      external_id: SecureRandom.uuid,
      public_key: SecureRandom.uuid,
      nickname: "Existing #{SecureRandom.hex(4)}"
    )
  end
end
