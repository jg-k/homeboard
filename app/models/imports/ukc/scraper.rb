require "ferrum"
require "nokogiri"

class Imports::Ukc::Scraper
  USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
               "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36".freeze

  STEALTH_JS = <<~JS.freeze
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
    Object.defineProperty(navigator, 'plugins', {
      get: () => [
        { name: 'Chrome PDF Plugin' },
        { name: 'Chrome PDF Viewer' },
        { name: 'Native Client' }
      ]
    });
    window.chrome = { runtime: {}, app: {}, csi: () => {}, loadTimes: () => {} };
  JS

  DEFAULT_LIMIT = 50
  ALLOWED_NRESULTS = [ 25, 50, 75, 100 ].freeze
  CF_TITLE = /just a moment|attention required|sorry/i

  GRADETYPE_TO_GEAR_STYLE = {
    1 => "sport",
    2 => "trad",
    4 => "boulder"
  }.freeze

  Row = Struct.new(:ukc_route_id, :ascent_date, :route_name, :grade, :quality,
                   :ascent_type, :gear_style, :partners, :crag_name, :crag_path,
                   :route_path, keyword_init: true)

  def initialize(user_id, limit: DEFAULT_LIMIT, browser_path: ENV["CHROME_BIN"] || "/usr/bin/google-chrome")
    @user_id = user_id
    @limit = limit
    @browser_path = browser_path
  end

  def call
    rows = GRADETYPE_TO_GEAR_STYLE.flat_map do |gradetype, gear_style|
      scrape_discipline(gradetype: gradetype, gear_style: gear_style)
    end

    rows = rows.sort_by { |r| r.ascent_date || Time.zone.at(0) }.reverse
    @limit ? rows.first(@limit) : rows
  end

  private

  def scrape_discipline(gradetype:, gear_style:)
    if @limit
      parse_rows(fetch(gradetype: gradetype, nresults: nresults_for(@limit)), gear_style: gear_style)
    else
      full_scrape(gradetype: gradetype, gear_style: gear_style)
    end
  end

  def nresults_for(limit)
    ALLOWED_NRESULTS.find { |n| n >= limit } || ALLOWED_NRESULTS.last
  end

  def full_scrape(gradetype:, gear_style:)
    first_html = fetch(gradetype: gradetype, nresults: ALLOWED_NRESULTS.last)
    years = parse_years(Nokogiri::HTML(first_html))
    return parse_rows(first_html, gear_style: gear_style) if years.empty?

    years.flat_map { |year| scrape_year(year, gradetype: gradetype, gear_style: gear_style) }
  end

  def scrape_year(year, gradetype:, gear_style:)
    rows = []
    pg = 1
    loop do
      html = fetch(gradetype: gradetype, year: year, pg: pg, nresults: ALLOWED_NRESULTS.last)
      page_rows = parse_rows(html, fixed_year: year, gear_style: gear_style)
      rows.concat(page_rows)

      max_pg = parse_max_page(Nokogiri::HTML(html))
      break if pg >= max_pg || page_rows.empty?

      pg += 1
    end
    rows
  end

  def fetch(gradetype: nil, year: nil, pg: 1, nresults: ALLOWED_NRESULTS.last)
    browser = Ferrum::Browser.new(
      headless: true,
      browser_path: @browser_path,
      timeout: 45,
      process_timeout: 45,
      window_size: [ 1366, 900 ],
      browser_options: {
        "no-sandbox" => nil,
        "disable-dev-shm-usage" => nil,
        "disable-blink-features" => "AutomationControlled",
        "lang" => "en-US,en"
      }
    )

    page = browser.create_page
    page.headers.set("User-Agent" => USER_AGENT, "Accept-Language" => "en-US,en;q=0.9")
    page.command("Page.addScriptToEvaluateOnNewDocument", source: STEALTH_JS)
    page.command("Network.setUserAgentOverride", userAgent: USER_AGENT, acceptLanguage: "en-US,en", platform: "Linux x86_64")
    page.go_to(url_for(gradetype: gradetype, year: year, pg: pg, nresults: nresults))
    wait_for_logbook(page)
    page.body
  ensure
    browser&.quit
  end

  def url_for(gradetype:, year:, pg:, nresults:)
    params = { id: @user_id, nresults: nresults, pg: pg }
    params[:gradetype] = gradetype if gradetype
    params[:year] = year if year
    "https://www.ukclimbing.com/logbook/showlog.php?#{params.to_query}"
  end

  def wait_for_logbook(page, attempts: 8, interval: 2)
    attempts.times do
      sleep interval
      return if page.body.to_s.include?("myLogbookTable")
    end
    raise "ukc blocked the request (CF challenge): #{page.title}" if page.title.to_s.match?(CF_TITLE)
  end

  def parse_rows(html, fixed_year: nil, gear_style: nil)
    doc = Nokogiri::HTML(html)
    table = doc.at_css("#myLogbookTable table")
    return [] unless table

    current_year = fixed_year || parse_years(doc).max || Time.zone.today.year
    prev_md = nil

    table.css("tbody tr").filter_map do |tr|
      md = parse_month_day(tr.at_css("td.logdate")&.text)
      next nil unless md

      current_year -= 1 if !fixed_year && prev_md && md > prev_md
      prev_md = md

      parse_row(tr, current_year, gear_style)
    end
  end

  def parse_years(doc)
    doc.css('select[name="year"] option').filter_map do |opt|
      opt["value"].to_s[/\A\d{4}\z/]&.to_i
    end.uniq.sort.reverse
  end

  def parse_max_page(doc)
    pg_input = doc.at_css("#pg")
    pg_input&.[]("data-slider-max").to_i.then { |n| n.positive? ? n : 1 }
  end

  def parse_row(tr, year, gear_style)
    route_anchor = tr.at_css("td.climb a.climbName")
    return nil unless route_anchor

    route_path = route_anchor["href"]
    grade, quality = parse_grade_cell(tr.at_css("td.grade")&.text)
    cells = tr.css("td").map(&:text).map { |t| t.strip.gsub(/\s+/, " ") }
    ascent_label = cells[2]&.presence
    partners = tr.at_css("td.partner")&.text&.strip&.presence
    date_text = tr.at_css("td.logdate")&.text.to_s.strip
    crag_anchor = tr.css("td a").find { |a| a["href"]&.match?(%r{/logbook/crags/[^/]+/?$}) }

    Row.new(
      ukc_route_id: extract_route_id(route_path),
      ascent_date: parse_date(date_text, year),
      route_name: route_anchor.text.strip,
      grade: grade,
      quality: quality,
      ascent_type: ascent_label,
      gear_style: gear_style,
      partners: partners,
      crag_name: crag_anchor&.text&.strip,
      crag_path: crag_anchor&.[]("href"),
      route_path: route_path
    )
  end

  def parse_grade_cell(text)
    return [ nil, nil ] if text.blank?

    cleaned = text.strip
    stars = cleaned.scan("*").size
    grade = cleaned.sub(/\s*\**\s*\z/, "").strip
    [ grade.presence, stars.positive? ? stars : nil ]
  end

  def extract_route_id(href)
    return nil if href.blank?

    href[%r{-(\d+)\z}, 1]
  end

  def parse_month_day(text)
    return nil if text.blank?

    cleaned = text.gsub(/(\d+)(st|nd|rd|th)/, '\1').strip
    date = Date.parse("#{cleaned} 2000")
    date.month * 100 + date.day
  rescue ArgumentError, Date::Error
    nil
  end

  def parse_date(text, year)
    return nil if text.blank?

    cleaned = text.gsub(/(\d+)(st|nd|rd|th)/, '\1')
    if cleaned.match?(/\b\d{4}\b/)
      Time.zone.parse(cleaned)
    else
      Time.zone.parse("#{cleaned} #{year}")
    end
  rescue ArgumentError
    nil
  end
end
