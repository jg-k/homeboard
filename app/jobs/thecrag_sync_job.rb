class ThecragSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id, username = nil, cookie = nil)
    user = User.find(user_id)
    name = username.presence || user.thecrag_username

    # A personal API key reads the climber's own logbook, so it needs neither a
    # username nor the borrowed admin session the scraper depends on.
    if user.thecrag_api_key.present?
      Imports::Thecrag::Sync.new(user: user, username: name).call
      return
    end

    return if name.blank?

    session = cookie.presence || Imports::Thecrag.session_cookie
    if session.blank?
      Rails.logger.warn("theCrag sync skipped for #{name}: no admin session cookie saved.")
      return
    end

    Imports::Thecrag::Sync.new(user: user, username: name, cookie: session).call

  # A revoked key or a spent weekly token budget is the climber's to sort out,
  # and retrying only burns more of the budget. So this is not a failed job --
  # but it is not a silent one either: settings would otherwise go on showing the
  # last successful sync as though nothing had changed.
  rescue Imports::Thecrag::Api::InvalidKey, Imports::Thecrag::Api::BudgetExhausted => e
    Rails.logger.warn("theCrag sync stopped for user #{user_id}: #{e.message}")
    user&.update_columns(thecrag_sync_error: e.message)
  end
end
