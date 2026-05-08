class UkcSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id, ukc_user_id = nil, full: false)
    user = User.find(user_id)
    id = ukc_user_id.presence || user.ukc_user_id
    return if id.blank?

    Imports::Ukc::Sync.new(user: user, ukc_user_id: id, full: full).call
  end
end
