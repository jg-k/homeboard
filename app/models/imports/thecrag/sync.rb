class Imports::Thecrag::Sync
  Result = Imports::Thecrag::Result

  # Two ways in, and the key wins whenever the climber has one: it reads their
  # own logbook with their own credentials instead of borrowing an admin's
  # session to scrape a page that theCrag would rather we left alone.
  def initialize(user:, username: nil, cookie: nil, api_key: nil, reader: nil, scraper: nil, full: false)
    @user = user
    @username = username || user.thecrag_username
    @api_key = (api_key || user.thecrag_api_key).presence
    @cookie = cookie
    @reader = reader || scraper
    @full = full
  end

  def call
    reader = @reader || build_reader
    rows = reader.call

    imported = 0
    skipped = 0
    errors = []
    read_epochs = []

    ActiveRecord::Base.transaction do
      rows.each do |row|
        if (existing = CragAscent.find_by(thecrag_ascent_id: row.thecrag_ascent_id))
          skipped += 1
          if refresh(existing, row)
            read_epochs << row.epoch
          else
            errors << "Ascent #{row.thecrag_ascent_id}: #{existing.errors.full_messages.join(', ')}"
          end
          next
        end

        ascent = CragAscent.new(
          thecrag_ascent_id: row.thecrag_ascent_id,
          thecrag_route_id: row.thecrag_route_id,
          thecrag_epoch: row.epoch,
          ascent_date: row.ascent_date,
          route_name: row.route_name,
          grade: row.grade,
          ascent_type: row.ascent_type,
          gear_style: row.gear_style,
          crag_name: row.crag_name,
          crag_path: row.crag_path,
          country: row.country,
          quality: row.quality,
          route_height: row.route_height,
          comment: row.comment,
          source: source
        )

        if ascent.save
          ascent.create_activity_log!(user: @user, performed_at: row.ascent_date)
          imported += 1
          read_epochs << row.epoch
        else
          errors << "Ascent #{row.thecrag_ascent_id}: #{ascent.errors.full_messages.join(', ')}"
        end
      end

      @user.update!(sync_attributes(read_epochs, truncated: truncated?(reader)))
    end

    Result.new(imported_count: imported, skipped_count: skipped, errors: errors)
  end

  private

  def api?
    @api_key.present?
  end

  def source
    api? ? "thecrag_api" : "thecrag_scrape"
  end

  def build_reader
    if api?
      Imports::Thecrag::Api.new(@api_key, since: since)
    else
      raise ArgumentError, "thecrag username is required" if @username.blank?
      raise ArgumentError, "a theCrag session cookie is required" if cookie.blank?

      Imports::Thecrag::Scraper.new(@username, cookie: cookie)
    end
  end

  # theCrag owns the climb, but not the note: a comment written here would
  # otherwise be overwritten by the one it was imported from.
  REFRESHABLE = %i[ascent_date route_name grade ascent_type gear_style crag_name
                   crag_path country quality route_height thecrag_route_id].freeze

  # An ascent edited on theCrag comes back with a higher epoch than the one we
  # stored, which is the only way to tell an edit from a row we have already
  # seen. The scraper sends no epoch, so it never overwrites the fuller record
  # the API left behind.
  def refresh(ascent, row)
    backfill_route(ascent, row)
    return true if row.epoch.blank?
    return true if ascent.thecrag_epoch && row.epoch <= ascent.thecrag_epoch

    attributes = REFRESHABLE.index_with { |name| row.public_send(name) }.compact
    return false unless ascent.update(attributes.merge(thecrag_epoch: row.epoch))

    ascent.activity_log&.update!(performed_at: row.ascent_date)
    true
  end

  # Ascents imported before we knew to store the route id are still the only
  # record of those climbs, so a sync fills the gap in rather than passing over
  # them and leaving them uncountable -- epoch or no epoch.
  def backfill_route(ascent, row)
    return if row.thecrag_route_id.blank? || ascent.thecrag_route_id.present?

    ascent.update_column(:thecrag_route_id, row.thecrag_route_id)
  end

  # Looked up late: only the scraper needs it, and finding it costs a query.
  def cookie
    @cookie ||= Imports::Thecrag.session_cookie
  end

  def truncated?(reader)
    reader.respond_to?(:truncated?) && reader.truncated?
  end

  # A full sync is the one that walks the whole logbook: the first one, or one
  # the caller asked for after a gap it does not trust.
  def since
    @full ? nil : @user.thecrag_since_epoch
  end

  # Remember how far the API got, so the next call asks only for what changed.
  # Duplicates count -- we did read them -- but an ascent that failed to save does
  # not: past the watermark, no later `since` will ever ask for it again.
  def sync_attributes(epochs, truncated:)
    attributes = { thecrag_synced_at: Time.current, thecrag_sync_error: nil }
    attributes[:thecrag_username] = @username if @username.present?

    # theCrag hands back the oldest ascents first, so a read that stopped at the
    # page cap stopped partway up the logbook rather than short of the bottom of
    # it: the highest epoch reached is exactly where the next sync resumes.
    if truncated
      attributes[:thecrag_sync_error] = "Only part of your logbook was read this time. " \
                                        "Sync again to carry on from where it stopped."
    end

    high_water = epochs.compact.max
    if high_water && high_water > @user.thecrag_since_epoch.to_i
      attributes[:thecrag_since_epoch] = high_water
    end

    attributes
  end
end
