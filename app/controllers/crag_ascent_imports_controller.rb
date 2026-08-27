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
    if username.blank? && !keeping_a_key?
      redirect_to settings_path, alert: "Please enter your theCrag username, or paste an API key."
      return
    end

    unless current_user.update(thecrag_attributes(username))
      redirect_to settings_path, alert: current_user.errors.full_messages.to_sentence
      return
    end

    ThecragSyncJob.perform_later(current_user.id, username.presence)
    redirect_to settings_path,
                notice: "Syncing your latest ascents from theCrag — refresh in a moment."
  end

  def sync_ukc
    ukc_user_id = extract_ukc_user_id(params[:ukc_user_id])
    if ukc_user_id.blank?
      redirect_to settings_path, alert: "Please enter your UKC user ID or logbook URL."
      return
    end

    current_user.update(ukc_user_id: ukc_user_id)
    UkcSyncJob.perform_later(current_user.id, ukc_user_id)
    redirect_to settings_path,
                notice: "Syncing your latest ascents from UKC — refresh in a moment."
  end

  private

  # The key field submits blank on every sync -- a password input cannot be
  # prefilled -- so blank means "leave the saved key alone". Clearing it is its
  # own checkbox, because there is no other way to tell the two apart.
  def thecrag_attributes(username)
    attributes = {}
    attributes[:thecrag_username] = username if username.present?
    key = params[:thecrag_api_key].to_s.strip

    if params[:remove_thecrag_api_key] == "1"
      attributes[:thecrag_api_key] = nil
      attributes[:thecrag_since_epoch] = nil
    elsif key.present?
      # A different key may point at a different logbook, so the incremental
      # watermark from the old one cannot be trusted.
      attributes[:thecrag_api_key] = key
      attributes[:thecrag_since_epoch] = nil if key != current_user.thecrag_api_key
    end

    # Forgetting the watermark is what a full re-sync is.
    attributes[:thecrag_since_epoch] = nil if params[:full_thecrag_resync] == "1"

    attributes
  end

  # A saved key identifies the climber by itself; only the scraper needs a name.
  def keeping_a_key?
    return false if params[:remove_thecrag_api_key] == "1"

    params[:thecrag_api_key].to_s.strip.present? || current_user.thecrag_api_key.present?
  end

  def extract_ukc_user_id(input)
    raw = input.to_s.strip
    return nil if raw.blank?

    raw[/\bid=(\d+)/, 1] || raw[/\A\d+\z/]
  end

  def import_service_for(csv_content)
    first_line = csv_content.force_encoding("UTF-8").delete_prefix("\uFEFF").lines.first.to_s

    if first_line.include?("Ascent ID")
      Imports::Thecrag.new(user: current_user, csv_content: csv_content)
    elsif first_line.include?("Pitches") || (first_line.include?("Name") && first_line.include?("Crag") && first_line.include?("Style"))
      Imports::Dlog.new(user: current_user, csv_content: csv_content)
    end
  end
end
