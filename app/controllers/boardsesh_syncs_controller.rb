class BoardseshSyncsController < ApplicationController
  def create
    if Rails.env.production?
      BoardseshSyncJob.perform_later(current_user.id)
      redirect_to settings_path, notice: "Sync started in background."
    else
      result = Boardsesh::Sync.new(user: current_user).call

      if result.errors.any?
        redirect_to settings_path, alert: result.errors.first
      else
        parts = []
        parts << "#{result.imported_count} #{'climb'.pluralize(result.imported_count)} imported"
        parts << "#{result.skipped_count} skipped" if result.skipped_count > 0
        redirect_to settings_path, notice: parts.join(", ")
      end
    end
  end
end
