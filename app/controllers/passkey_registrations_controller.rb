class PasskeyRegistrationsController < ApplicationController
  # Creation options for an account that does not exist yet. The chosen name,
  # the user handle and the challenge are all held in the session: nothing is
  # written to the database until the authenticator has actually signed, so an
  # abandoned biometric prompt leaves no half-made account behind.
  def new
    user = User.new(display_name: params[:display_name])
    user.validate

    if user.errors[:display_name].any?
      return render json: { error: "Display name #{user.errors[:display_name].first}" },
        status: :unprocessable_entity
    end

    options = WebAuthn::Credential.options_for_create(
      user: {
        id: WebAuthn.generate_user_id,
        name: user.display_name,
        display_name: user.display_name
      },
      authenticator_selection: {
        resident_key: "required",
        user_verification: "required"
      },
      relying_party: relying_party
    )

    session[:pending_passkey_registration] = {
      "display_name" => user.display_name,
      "webauthn_id" => options.user.id,
      "challenge" => options.challenge
    }

    render json: options
  end

  def create
    pending = session.delete(:pending_passkey_registration)
    return failed("That sign-up expired. Please try again.") if pending.blank?

    credential = WebAuthn::Credential.from_create(JSON.parse(params[:credential]), relying_party: relying_party)
    credential.verify(pending["challenge"], user_verification: true)

    user = User.new(
      display_name: pending["display_name"],
      webauthn_id: pending["webauthn_id"],
      password: Devise.friendly_token[0, 20]
    )
    user.passkeys.build(
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: credential.sign_count
    )

    return failed(user.errors.full_messages.to_sentence) unless user.save

    user.remember_me = true
    sign_in(user, event: :authentication)
    redirect_to after_sign_in_path_for(user), notice: "Welcome to Homeboard, #{user.display_name}."
  rescue JSON::ParserError, WebAuthn::Error => e
    Rails.logger.warn("Passkey sign-up failed: #{e.class}: #{e.message}")
    failed("That passkey could not be verified. Please try again.")
  end

  private

  def failed(message)
    redirect_to new_user_registration_path, alert: message
  end

  def relying_party
    @relying_party ||= Passkey::RelyingParty.for(request)
  end
end
