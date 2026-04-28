class BoardseshSyncAllJob < ApplicationJob
  queue_as :default

  def perform
    User.where.not(boardsesh_user_id: nil).find_each do |user|
      BoardseshSyncJob.perform_later(user.id)
    end
  end
end
