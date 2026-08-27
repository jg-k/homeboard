class Imports::Thecrag
  Result = Struct.new(:imported_count, :skipped_count, :errors, keyword_init: true)

  # One admin lends their theCrag session to fetch every user's logbook, so the
  # cookie lives on an admin row rather than on the climber being synced.
  def self.session_cookie
    User.admin.where.not(thecrag_session_cookie: [ nil, "" ]).pick(:thecrag_session_cookie)
  end

  ASCENT_TYPE_MAP = {
    "Onsight" => "onsight",
    "Flash" => "flash",
    "Red point" => "redpoint",
    "Redpoint" => "redpoint",
    "Send" => "send",
    "Tick" => "tick",
    "Attempt" => "attempt",
    "Hang dog" => "hang_dog",
    "Clean" => "clean",
    "Pink point" => "pink_point"
  }.freeze

  GEAR_STYLE_MAP = {
    "Sport" => "sport",
    "Trad" => "trad",
    "Boulder" => "boulder"
  }.freeze

  # The API reports ticks as machine labels rather than the prose the ascents
  # page prints, and it knows more of them than we store. Anything we have no
  # column for -- top ropes, retreats -- lands as the closest thing we do.
  TICK_LABEL_MAP = {
    "onsight" => "onsight",
    "flash" => "flash",
    "redpoint" => "redpoint",
    "pinkpoint" => "pink_point",
    "send" => "send",
    "secondgo" => "send",
    "groundup" => "send",
    "clean" => "clean",
    "allfreewithrest" => "clean",
    "tick" => "tick",
    "ticked" => "tick",
    "repeat" => "tick",
    "toprope" => "tick",
    "topropeonsight" => "tick",
    "topropeflash" => "tick",
    "hangdog" => "hang_dog",
    "dogged" => "hang_dog",
    "attempt" => "attempt",
    "working" => "attempt",
    "retreat" => "attempt"
  }.freeze

  # What both readers hand to Imports::Thecrag::Sync. The scraper fills in what
  # the ascents page shows; the API fills in everything, `epoch` included --
  # that timestamp is what makes the next sync incremental.
  Row = Struct.new(:thecrag_ascent_id, :thecrag_route_id, :ascent_date, :route_name,
                   :grade, :ascent_type, :gear_style, :crag_name, :crag_path,
                   :country, :quality, :route_height, :comment, :epoch,
                   keyword_init: true)

  def initialize(user:, csv_content:)
    @user = user
    @csv_content = csv_content
  end

  def call
    imported_count = 0
    skipped_count = 0
    errors = []

    content = strip_bom(@csv_content)
    rows = CSV.parse(content, headers: true)

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        ascent_id = row["Ascent ID"].presence

        if ascent_id && CragAscent.exists?(thecrag_ascent_id: ascent_id)
          skipped_count += 1
          next
        end

        ascent_date = parse_date(row["Ascent Date"])
        if ascent_date.nil?
          errors << "Row #{index + 2}: missing or invalid date"
          next
        end

        crag_ascent = CragAscent.new(
          route_name: row["Route Name"] || row["Route"],
          ascent_type: ASCENT_TYPE_MAP[row["Ascent Type"]],
          gear_style: GEAR_STYLE_MAP[row["Ascent Gear Style"].presence || row["Route Gear Style"]],
          grade: row["Ascent Grade"].presence || row["Route Grade"],
          route_height: row["Route Height"].presence&.to_i,
          crag_name: row["Crag Name"],
          crag_path: row["Crag Path"],
          country: row["Country"],
          partners: row["With"],
          comment: row["Comment"],
          quality: parse_quality(row["Quality"]),
          ascent_date: ascent_date,
          thecrag_ascent_id: ascent_id,
          thecrag_route_id: row["Route ID"].presence,
          source: "thecrag"
        )

        if crag_ascent.save
          crag_ascent.create_activity_log!(user: @user, performed_at: ascent_date)
          imported_count += 1
        else
          errors << "Row #{index + 2}: #{crag_ascent.errors.full_messages.join(', ')}"
        end
      end
    end

    Result.new(imported_count: imported_count, skipped_count: skipped_count, errors: errors)
  end

  private

  def strip_bom(content)
    content.force_encoding("UTF-8")
    content.delete_prefix!("\uFEFF")
    content
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    Time.zone.parse(date_string)
  rescue ArgumentError
    nil
  end

  def parse_quality(value)
    return nil if value.blank?

    value.count("*") if value.include?("*")
  end
end
