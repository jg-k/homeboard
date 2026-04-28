require "ferrum"
require "nokogiri"

class Imports::Thecrag::Scraper
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

  Row = Struct.new(:thecrag_ascent_id, :ascent_date, :route_name, :grade,
                   :ascent_type, :gear_style, :crag_name, :crag_path,
                   :country, :quality, :route_height, keyword_init: true)

  def initialize(username, browser_path: ENV["CHROME_BIN"] || "/usr/bin/google-chrome")
    @username = username
    @browser_path = browser_path
  end

  def call
    parse(fetch_html)
  end

  private

  def fetch_html
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
    page.go_to("https://www.thecrag.com/en/climber/#{@username}/ascents")
    sleep 3

    if page.title.to_s.match?(/just a moment|attention required|sorry/i)
      raise "thecrag blocked the request (CF challenge): #{page.title}"
    end

    page.body
  ensure
    browser&.quit
  end

  def parse(html)
    doc = Nokogiri::HTML(html)
    table = doc.css("table").max_by { |t| t.css("tr").size }
    return [] unless table

    rows = []
    current_date = nil
    current_crag = nil
    current_path = nil
    current_country = nil

    table.css("tr").each do |tr|
      if tr.css("td.group").any? && tr.css("td.subheader").empty?
        date, crag, path, country = parse_group_row(tr)
        current_date    = date if date
        current_crag    = crag if crag
        current_path    = path if path
        current_country = country if country
      elsif tr["class"] == "actionable"
        row = parse_ascent_row(tr, current_date, current_crag, current_path, current_country)
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
    crag = anchor&.text&.strip
    path = anchor&.[]("href")
    country = parse_country(anchor)
    [ date, crag, path, country ]
  end

  def parse_country(anchor)
    return nil unless anchor

    title = anchor["title"].to_s
    return nil if title.blank?

    parts = title.split("›").map(&:strip)
    parts[2] if parts.size > 2
  end

  def parse_ascent_row(tr, date, crag, path, country)
    ascent_id = tr["data-ascentid"].presence
    return nil unless ascent_id && date

    tick_node = tr.css("[class^=tick_]").first
    tick_title = tick_node&.[]("title").to_s
    ascent_label, gear_label = tick_title.split(":").map(&:strip)

    grade = tr.css("td span[class*=gb]").first&.text&.strip
    route_anchor = tr.css("span.route a").first
    route_name = route_anchor&.text&.strip
    quality = tr.text.scan("★").size
    height = tr.text[/(\d+)\s*m\b/, 1]&.to_i

    Row.new(
      thecrag_ascent_id: ascent_id,
      ascent_date: date,
      route_name: route_name,
      grade: grade,
      ascent_type: ascent_label,
      gear_style: gear_label,
      crag_name: crag,
      crag_path: path,
      country: country,
      quality: (quality.positive? ? quality : nil),
      route_height: height
    )
  end

  def parse_date(string)
    cleaned = string.gsub(/(\d+)(st|nd|rd|th)/, '\1')
    Time.zone.parse(cleaned)
  rescue ArgumentError
    nil
  end
end
