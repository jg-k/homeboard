class UkcSyncAllJob < ApplicationJob
  queue_as :default

  def perform
    User.where.not(ukc_user_id: nil).find_each do |user|
      UkcSyncJob.perform_later(user.id)
    end
  end
end
