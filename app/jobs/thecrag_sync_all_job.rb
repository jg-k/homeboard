class ThecragSyncAllJob < ApplicationJob
  queue_as :default

  def perform
    # A key holder is worth syncing whether or not we know their username --
    # the key identifies them on theCrag's side.
    User.where.not(thecrag_username: nil).or(User.where.not(thecrag_api_key: nil)).find_each do |user|
      ThecragSyncJob.perform_later(user.id)
    end
  end
end
