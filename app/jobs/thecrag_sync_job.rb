class ThecragSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id, username = nil, cookie = nil)
    user = User.find(user_id)
    name = username.presence || user.thecrag_username
    return if name.blank?

    session = cookie.presence || Imports::Thecrag.session_cookie
    if session.blank?
      Rails.logger.warn("theCrag sync skipped for #{name}: no admin session cookie saved.")
      return
    end

    Imports::Thecrag::Sync.new(user: user, username: name, cookie: session).call
  end
end
