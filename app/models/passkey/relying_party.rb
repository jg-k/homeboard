# Which domain owns the passkeys.
#
# Production uses the configured canonical host: authenticators bind every
# credential to it, so a drift there would silently invalidate passkeys people
# already registered. Outside production we follow the request instead, so the
# ceremony works on whatever port or tunnel host the app is served from.
class Passkey::RelyingParty
  def self.for(request)
    return WebAuthn.configuration.relying_party if Rails.env.production?

    WebAuthn::RelyingParty.new(
      name: WebAuthn.configuration.rp_name,
      id: request.host,
      allowed_origins: [ request.base_url ]
    )
  end
end
