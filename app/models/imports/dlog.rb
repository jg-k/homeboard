class Imports::Dlog
  Result = Struct.new(:imported_count, :skipped_count, :errors, keyword_init: true)

  STYLE_MAP = {
    "Lead O/S" => "onsight",
    "Lead Flash" => "flash",
    "Lead RP" => "redpoint",
    "Lead" => "redpoint",
    "Lead dog" => "hang_dog",
    "Lead G/U" => "send",
    "AltLd" => "redpoint",
    "Solo" => "send",
    "Sent" => "send",
    "Flash" => "flash",
    "O/S" => "onsight",
    "Top Rope" => "tick",
    "2nd" => "tick",
    "Attempt" => "attempt",
    "Hang" => "hang_dog"
  }.freeze

  GEAR_STYLE_MAP = {
    "Sport" => "sport",
    "Trad" => "trad",
    "Boulder" => "boulder"
  }.freeze

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
        ascent_date = parse_date(row["Date"])
        if ascent_date.nil?
          errors << "Row #{index + 2}: missing or invalid date"
          next
        end

        route_name = row["Name"]
        crag_name = row["Crag"]

        if duplicate?(route_name, ascent_date, crag_name)
          skipped_count += 1
          next
        end

        crag_ascent = CragAscent.new(
          route_name: route_name,
          grade: row["Grade"],
          ascent_type: STYLE_MAP[row["Style"]],
          gear_style: GEAR_STYLE_MAP[row["Type"]],
          crag_name: crag_name,
          country: row["Country"],
          partners: row["Partner(empty)"],
          comment: row["Notes"] && CGI.unescapeHTML(row["Notes"]),
          ascent_date: ascent_date,
          source: "ukc_dlog"
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

    if date_string.match?(%r{\A\?{3}/\d{2,4}\z})
      year = date_string.split("/").last.to_i
      year += 2000 if year < 100
      return Date.new(year, 1, 1).in_time_zone
    end

    normalized = date_string.gsub("??", "01")
    Date.parse(normalized).in_time_zone
  rescue ArgumentError, Date::Error
    nil
  end

  def duplicate?(route_name, ascent_date, crag_name)
    CragAscent.joins(:activity_log)
      .where(activity_logs: { user_id: @user.id })
      .where(route_name: route_name, crag_name: crag_name, ascent_date: ascent_date)
      .exists?
  end
end
