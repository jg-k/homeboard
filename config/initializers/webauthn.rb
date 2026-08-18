# frozen_string_literal: true

# Passkeys (WebAuthn). These are the production values; `Passkey::RelyingParty`
# decides which relying party each request actually uses.
WebAuthn.configure do |config|
  config.rp_name = "Homeboard"
  config.rp_id = "homeboard.zone"
  config.allowed_origins = [ "https://homeboard.zone" ]
end
