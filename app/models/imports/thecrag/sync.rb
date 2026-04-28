class Imports::Thecrag::Sync
  Result = Imports::Thecrag::Result

  def initialize(user:, username: nil, scraper: nil)
    @user = user
    @username = username || user.thecrag_username
    @scraper = scraper
  end

  def call
    raise ArgumentError, "thecrag username is required" if @username.blank?

    rows = (@scraper || Imports::Thecrag::Scraper.new(@username)).call

    imported = 0
    skipped = 0
    errors = []

    ActiveRecord::Base.transaction do
      rows.each do |row|
        if CragAscent.exists?(thecrag_ascent_id: row.thecrag_ascent_id)
          skipped += 1
          next
        end

        ascent = CragAscent.new(
          thecrag_ascent_id: row.thecrag_ascent_id,
          ascent_date: row.ascent_date,
          route_name: row.route_name,
          grade: row.grade,
          ascent_type: Imports::Thecrag::ASCENT_TYPE_MAP[row.ascent_type],
          gear_style: Imports::Thecrag::GEAR_STYLE_MAP[row.gear_style],
          crag_name: row.crag_name,
          crag_path: row.crag_path,
          country: row.country,
          quality: row.quality,
          route_height: row.route_height,
          source: "thecrag_scrape"
        )

        if ascent.save
          ascent.create_activity_log!(user: @user, performed_at: row.ascent_date)
          imported += 1
        else
          errors << "Ascent #{row.thecrag_ascent_id}: #{ascent.errors.full_messages.join(', ')}"
        end
      end

      @user.update!(thecrag_username: @username, thecrag_synced_at: Time.current)
    end

    Result.new(imported_count: imported, skipped_count: skipped, errors: errors)
  end
end
