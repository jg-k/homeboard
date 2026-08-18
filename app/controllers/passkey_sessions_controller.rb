class PasskeySessionsController < ApplicationController
  # Request options for the sign-in ceremony. No allow list is sent: passkeys
  # are registered as discoverable credentials, so the authenticator tells us
  # who the user is and the sign-in page needs no email or username field.
  def new
    options = WebAuthn::Credential.options_for_get(
      user_verification: "required",
      relying_party: relying_party
    )

    session[:passkey_authentication_challenge] = options.challenge

    render json: options
  end

  def create
    challenge = session.delete(:passkey_authentication_challenge)
    return failed("That sign-in expired. Please try again.") if challenge.blank?

    credential = WebAuthn::Credential.from_get(JSON.parse(params[:credential]), relying_party: relying_party)
    passkey = Passkey.find_by(external_id: credential.id)
    return failed("That passkey is not registered here.") if passkey.nil?

    credential.verify(
      challenge,
      public_key: passkey.public_key,
      sign_count: passkey.sign_count,
      user_verification: true
    )

    # For a discoverable credential the authenticator also reports which user it
    # signed for. It must be the account the credential is stored against, or a
    # stolen credential id could be pointed at someone else's row.
    handle = credential.user_handle
    return failed("That passkey could not be verified.") if handle.present? && handle != passkey.user.webauthn_id

    passkey.used!(credential.sign_count)
    sign_in_with(passkey.user)
  rescue JSON::ParserError, WebAuthn::Error => e
    Rails.logger.warn("Passkey sign-in failed: #{e.class}: #{e.message}")
    failed("That passkey could not be verified. Please try again.")
  end

  private

  def sign_in_with(user)
    user.remember_me = true
    sign_in(user, event: :authentication)
    redirect_to after_sign_in_path_for(user), notice: "Signed in with your passkey."
  end

  def failed(message)
    redirect_to new_user_session_path, alert: message
  end

  def relying_party
    @relying_party ||= Passkey::RelyingParty.for(request)
  end
end
