require "nokogiri"

# Reads a climber's logbook off theCrag.
#
# theCrag stopped serving logbooks to anonymous visitors: without a session the
# ascents page 302s to /home and there is nothing to parse. So every fetch
# carries a session cookie lifted from a signed-in browser, and a bounce back to
# /home means that cookie has expired.
class Imports::Thecrag::Scraper
  class SessionExpired < StandardError; end

  # theCrag lists ascents newest first, so one page -- the most recent hundred --
  # is all a repeat sync needs. History comes from the CSV import instead:
  # walking all fourteen pages of a long logbook is what earns a 429. Pass a
  # bigger `pages:` only when you mean to.
  DEFAULT_PAGES = 1
  MAX_PAGES = 40

  # Even two page loads back to back are worth spacing out; a sync is a
  # background job and nobody is watching the clock.
  PAGE_PAUSE = 1.5

  Row = Struct.new(:thecrag_ascent_id, :ascent_date, :route_name, :grade,
                   :ascent_type, :gear_style, :crag_name, :crag_path,
                   :country, :quality, :route_height, keyword_init: true)

  def initialize(username, cookie:, pages: DEFAULT_PAGES, http: nil, pause: PAGE_PAUSE)
    @username = username
    @cookie = cookie
    @pages = pages.clamp(1, MAX_PAGES)
    @pause = pause
    @http = http || Imports::Http.new(cookie: normalized_cookie(cookie))
  end

  def call
    rows = []
    page = 1

    loop do
      html = fetch(page)
      page_rows = parse(html)
      rows.concat(page_rows)

      last = page == 1 ? last_page(html) : @last_page
      @last_page = last
      break if page_rows.empty? || page >= [ last, @pages ].min

      page += 1
      sleep @pause if @pause.to_f.positive?
    end

    rows
  end

  private

  # Accepts either a bare session id or a full "name=value; ..." cookie header.
  def normalized_cookie(cookie)
    value = cookie.to_s.strip
    value.include?("=") ? value : "ApacheSessionID=#{value}"
  end

  def fetch(page)
    url = "https://www.thecrag.com/en/climber/#{@username}/ascents"
    url += "?page=#{page}" if page > 1

    response = @http.get(url)

    if response.url.to_s.end_with?("/home") || response.url.to_s.include?("/processmap/login")
      raise SessionExpired, "theCrag sent us to #{response.url} -- the session cookie is no longer valid."
    end
    if response.status == 429
      raise Imports::Http::RateLimited,
            "theCrag is rate limiting us (HTTP 429). Wait a few minutes before syncing again."
    end
    raise Imports::Http::Error, "theCrag returned HTTP #{response.status}" unless response.ok?

    response.body
  end

  # The pager links to every page, so the highest one it mentions is the last.
  def last_page(html)
    pages = html.scan(%r{/ascents\?page=(\d+)}).flatten.map(&:to_i)
    pages.max || 1
  end

  def parse(html)
    doc = Nokogiri::HTML(html)
    table = doc.css("table").max_by { |t| t.css("tr").size }
    return [] unless table

    rows = []
    current_date = nil
    current_crag = nil
    current_path = nil

    table.css("tr").each do |tr|
      if tr.css("td.group").any? && tr.css("td.subheader").empty?
        date, crag, path = parse_group_row(tr)
        current_date = date if date
        current_crag = crag if crag
        current_path = path if path
      elsif tr["class"] == "actionable"
        row = parse_ascent_row(tr, current_date, current_crag, current_path)
        rows << row if row
      end
    end

    rows
  end

  def parse_group_row(tr)
    text = tr.text.strip.gsub(/\s+/, " ")
    date = nil
    if (m = text.match(/^(\w+\s+\d+\w+\s+\w+\s+\d{4})\s*-/))
      date = parse_date(m[1])
    end
    anchor = tr.css("a").first
    [ date, anchor&.text&.strip, anchor&.[]("href") ]
  end

  # The route link carries the full breadcrumb -- "World › Europe › United
  # Kingdom › ..." -- and the country is the third step. The group row used to
  # carry this too, but no longer has a title attribute at all.
  def parse_country(anchor)
    title = anchor&.[]("title").to_s
    return nil if title.blank?

    parts = title.tr(" ", " ").split("›").map(&:strip)
    parts[2].presence
  end

  def parse_ascent_row(tr, date, crag, path)
    ascent_id = tr["data-ascentid"].presence
    return nil unless ascent_id && date

    tick_node = tr.css("[class^=tick_]").first
    tick_title = tick_node&.[]("title").to_s
    ascent_label, gear_label = tick_title.split(":").map(&:strip)

    grade = tr.css("td span[class*=gb]").first&.text&.strip
    route_anchor = tr.css("span.route a").first

    Row.new(
      thecrag_ascent_id: ascent_id,
      ascent_date: date,
      route_name: route_name_from(route_anchor),
      grade: grade,
      ascent_type: ascent_label,
      gear_style: gear_label,
      crag_name: crag,
      crag_path: path,
      country: parse_country(route_anchor),
      quality: (tr.text.scan("★").size.positive? ? tr.text.scan("★").size : nil),
      route_height: tr.text[/(\d+)\s*m\b/, 1]&.to_i
    )
  end

  # The quality stars live inside the route link, so the anchor's own text reads
  # "★★ Magic Flute". Drop them -- they are already counted into quality.
  def route_name_from(anchor)
    return nil unless anchor

    without_stars = anchor.dup
    without_stars.css("span.star").remove
    without_stars.text.strip.presence
  end

  def parse_date(string)
    cleaned = string.gsub(/(\d+)(st|nd|rd|th)/, '\1')
    Time.zone.parse(cleaned)
  rescue ArgumentError
    nil
  end
end
