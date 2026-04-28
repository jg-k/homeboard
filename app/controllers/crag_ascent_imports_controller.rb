class CragAscentImportsController < ApplicationController
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_MIME_TYPES = %w[text/csv application/csv application/vnd.ms-excel text/plain].freeze

  before_action :authenticate_user!

  def new
  end

  def create
    unless params[:file].present?
      redirect_to new_crag_ascent_import_path, alert: "Please select a CSV file to upload."
      return
    end

    file = params[:file]

    if file.size > MAX_FILE_SIZE
      redirect_to new_crag_ascent_import_path, alert: "File is too large. Maximum size is #{MAX_FILE_SIZE / 1.megabyte}MB."
      return
    end

    unless ALLOWED_MIME_TYPES.include?(file.content_type) || file.original_filename.to_s.downcase.end_with?(".csv")
      redirect_to new_crag_ascent_import_path, alert: "Invalid file type. Please upload a CSV file."
      return
    end

    csv_content = file.read
    service = import_service_for(csv_content)

    unless service
      redirect_to new_crag_ascent_import_path, alert: "Unrecognized CSV format. Please upload a theCrag or DLOG export."
      return
    end

    result = service.call

    if result.errors.any?
      flash[:alert] = "Import completed with errors: #{result.errors.first}"
    end

    redirect_to activity_path,
                notice: "Imported #{result.imported_count} ascent#{'s' if result.imported_count != 1}, " \
                        "skipped #{result.skipped_count} duplicate#{'s' if result.skipped_count != 1}."
  end

  def sync_thecrag
    username = params[:thecrag_username].to_s.strip
    if username.blank?
      redirect_to new_crag_ascent_import_path, alert: "Please enter your theCrag username."
      return
    end

    current_user.update(thecrag_username: username)
    ThecragSyncJob.perform_later(current_user.id, username)
    redirect_to new_crag_ascent_import_path,
                notice: "Syncing your latest ascents from theCrag — refresh in a moment."
  end

  private

  def import_service_for(csv_content)
    first_line = csv_content.force_encoding("UTF-8").delete_prefix("\uFEFF").lines.first.to_s

    if first_line.include?("Ascent ID")
      Imports::Thecrag.new(user: current_user, csv_content: csv_content)
    elsif first_line.include?("Pitches") || (first_line.include?("Name") && first_line.include?("Crag") && first_line.include?("Style"))
      Imports::Dlog.new(user: current_user, csv_content: csv_content)
    end
  end
end
