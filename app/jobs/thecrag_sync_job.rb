class ThecragSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id, username = nil)
    user = User.find(user_id)
    name = username.presence || user.thecrag_username
    return if name.blank?

    Imports::Thecrag::Sync.new(user: user, username: name).call
  end
end
