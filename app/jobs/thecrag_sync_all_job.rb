class ThecragSyncAllJob < ApplicationJob
  queue_as :default

  def perform
    User.where.not(thecrag_username: nil).find_each do |user|
      ThecragSyncJob.perform_later(user.id)
    end
  end
end
