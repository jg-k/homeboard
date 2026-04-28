class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @grading_systems = GradingSystem.for_user(current_user).order(:name)
  end

  def toggle_allow_follows
    current_user.update(allow_follows: params[:allow_follows] == "on")
    redirect_to settings_path, notice: "Settings updated."
  end

  def export_json
    json = ActivityExport.new(user: current_user).to_json
    send_data json, filename: "homeboard_export_#{Date.current.iso8601}.json", type: "application/json"
  end

  def export_csv
    zip = ActivityExport.new(user: current_user).to_csv_zip
    send_data zip, filename: "homeboard_export_#{Date.current.iso8601}.zip", type: "application/zip"
  end

  def clear_imported_ascents
    ascents = CragAscent.joins(:activity_log).where(activity_logs: { user_id: current_user.id })
    count = ascents.count
    ascents.destroy_all
    redirect_to settings_path, notice: "#{count} imported ascent#{'s' if count != 1} deleted."
  end
end
