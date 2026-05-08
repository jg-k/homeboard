class Imports::Ukc::Sync
  Result = Imports::Ukc::Result

  def initialize(user:, ukc_user_id: nil, full: false, scraper: nil)
    @user = user
    @ukc_user_id = ukc_user_id || user.ukc_user_id
    @full = full
    @scraper = scraper
  end

  def call
    raise ArgumentError, "ukc user id is required" if @ukc_user_id.blank?

    rows = (@scraper || Imports::Ukc::Scraper.new(@ukc_user_id, limit: @full ? nil : Imports::Ukc::Scraper::DEFAULT_LIMIT)).call

    imported = 0
    skipped = 0
    errors = []

    ActiveRecord::Base.transaction do
      rows.each do |row|
        if row.ascent_date.nil?
          errors << "Row #{row.route_name || row.ukc_route_id}: missing or invalid date"
          next
        end

        if duplicate?(row)
          skipped += 1
          next
        end

        ascent = CragAscent.new(
          ukc_route_id: row.ukc_route_id,
          ascent_date: row.ascent_date,
          route_name: row.route_name,
          grade: row.grade,
          quality: row.quality,
          ascent_type: Imports::Ukc::ASCENT_TYPE_MAP[row.ascent_type],
          gear_style: row.gear_style,
          partners: row.partners,
          crag_name: row.crag_name,
          crag_path: row.crag_path,
          source: "ukc_scrape"
        )

        if ascent.save
          ascent.create_activity_log!(user: @user, performed_at: row.ascent_date)
          imported += 1
        else
          errors << "Ascent #{row.route_name}: #{ascent.errors.full_messages.join(', ')}"
        end
      end

      @user.update!(ukc_user_id: @ukc_user_id, ukc_synced_at: Time.current)
    end

    Result.new(imported_count: imported, skipped_count: skipped, errors: errors)
  end

  private

  def duplicate?(row)
    scope = CragAscent.joins(:activity_log).where(activity_logs: { user_id: @user.id })

    if row.ukc_route_id.present?
      scope.where(ukc_route_id: row.ukc_route_id, ascent_date: row.ascent_date).exists?
    else
      scope.where(route_name: row.route_name, crag_name: row.crag_name, ascent_date: row.ascent_date).exists?
    end
  end
end
