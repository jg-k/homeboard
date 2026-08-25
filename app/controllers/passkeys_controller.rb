class PasskeysController < ApplicationController
  before_action :authenticate_user!

  # Creation options for the browser ceremony. The challenge is held in the
  # session so the attestation posted back to #create can only ever satisfy
  # this one request.
  def new
    options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_handle,
        name: current_user.email,
        display_name: current_user.email
      },
      exclude: current_user.passkeys.pluck(:external_id),
      authenticator_selection: {
        resident_key: "required",
        user_verification: "required"
      },
      relying_party: relying_party
    )

    session[:passkey_challenge] = options.challenge

    render json: options
  end

  def create
    challenge = session.delete(:passkey_challenge)
    return redirect_to settings_path, alert: "That registration expired. Please try again." if challenge.blank?

    credential = WebAuthn::Credential.from_create(JSON.parse(params[:credential]), relying_party: relying_party)
    credential.verify(challenge, user_verification: true)

    passkey = current_user.passkeys.build(
      **Passkey.attributes_from(credential),
      nickname: params[:nickname].presence
    )

    if passkey.save
      redirect_to settings_path, notice: "#{passkey.nickname} added."
    else
      redirect_to settings_path, alert: passkey.errors.full_messages.to_sentence
    end
  rescue JSON::ParserError, WebAuthn::Error => e
    Rails.logger.warn("Passkey registration failed: #{e.class}: #{e.message}")
    redirect_to settings_path, alert: "That passkey could not be verified. Please try again."
  end

  def destroy
    passkey = current_user.passkeys.find(params[:id])
    passkey.destroy
    redirect_to settings_path, notice: "#{passkey.nickname} removed."
  end

  private

  def relying_party
    @relying_party ||= Passkey::RelyingParty.for(request)
  end
end
