# Identifies the deployed build.
#
# Kamal injects KAMAL_VERSION (the git SHA of the deployed commit) into every
# app container, so this changes on every deploy. The service worker embeds it,
# which is what makes the browser notice the update and re-warm offline caches
# that would otherwise serve pre-deploy HTML forever.
Rails.application.config.x.build_version = ENV["KAMAL_VERSION"].presence || "dev"
