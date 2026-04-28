Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Set traces_sample_rate to capture performance data
  # Adjust this value in production (0.0 to 1.0)
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0.1).to_f

  # Set profiles_sample_rate to profile transactions
  # Requires traces_sample_rate to be set
  config.profiles_sample_rate = ENV.fetch("SENTRY_PROFILES_SAMPLE_RATE", 0.1).to_f

  # Only send errors in production by default
  config.enabled_environments = %w[production]
end
