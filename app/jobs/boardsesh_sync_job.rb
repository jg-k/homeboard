class BoardseshSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return unless user.boardsesh_user_id.present?

    Boardsesh::Sync.new(user: user).call
  end
end
