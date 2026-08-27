require "test_helper"

class Imports::Thecrag::ScraperTest < ActiveSupport::TestCase
  # A trimmed slice of a real logged-in ascents page.
  FIXTURE = Rails.root.join("test/fixtures/files/thecrag-ascents.html").read

  # Stands in for Imports::Http, recording what was asked for.
  class FakeHttp
    attr_reader :requested

    def initialize(pages, final_url: nil, status: 200)
      @pages = pages
      @final_url = final_url
      @status = status
      @requested = []
    end

    def get(url)
      @requested << url
      Imports::Http::Response.new(status: @status, body: @pages.shift || @pages.last, url: @final_url || url)
    end
  end

  def scraper(http, **options)
    Imports::Thecrag::Scraper.new("jegk", cookie: "abc", http: http, pause: 0, **options)
  end

  test "parses the ascents off a logged-in page" do
    rows = scraper(FakeHttp.new([ FIXTURE ], final_url: "https://www.thecrag.com/en/climber/jegk/ascents")).call

    assert_equal 3, rows.size
    assert rows.all? { |r| r.thecrag_ascent_id.present? }
    assert rows.all? { |r| r.ascent_date.present? }
    assert rows.all? { |r| r.crag_name.present? }
  end

  # Counting goes on a route means grouping ascents by it, and the route link is
  # the only place the page names it.
  test "reads the route id out of the route link" do
    rows = scraper(FakeHttp.new([ FIXTURE ])).call

    assert_equal "8043159375", rows.first.thecrag_route_id
  end

  # The quality stars sit inside the route link, so the anchor's own text reads
  # "★ The Killing Fields".
  test "keeps the stars out of the route name" do
    rows = scraper(FakeHttp.new([ FIXTURE ])).call

    assert rows.none? { |r| r.route_name.include?("★") }, rows.map(&:route_name).inspect
    starred = rows.find { |r| r.quality.to_i.positive? }
    assert starred, "expected a fixture row with a quality rating"
    assert_no_match(/\A[★\s]/, starred.route_name)
  end

  # The group row lost its title attribute; the country now has to come off the
  # route link's breadcrumb, whose separators are non-breaking spaces.
  test "reads the country from the route breadcrumb" do
    rows = scraper(FakeHttp.new([ FIXTURE ])).call

    assert_equal [ "United Kingdom" ], rows.map(&:country).uniq
  end

  # Ascents come newest first, so a repeat sync only needs the front of the
  # list; history arrives via the CSV import. Walking a whole logbook is what
  # got us rate limited.
  test "reads only the first page even when more are advertised" do
    http = FakeHttp.new([ FIXTURE, FIXTURE, FIXTURE ])

    rows = scraper(http).call

    assert_equal 1, http.requested.size
    assert_equal "https://www.thecrag.com/en/climber/jegk/ascents", http.requested.first
    assert_equal 3, rows.size
  end

  test "a deeper walk can be asked for explicitly" do
    http = FakeHttp.new([ FIXTURE, FIXTURE, FIXTURE ])

    scraper(http, pages: 3).call

    assert_equal 3, http.requested.size
    assert_equal "https://www.thecrag.com/en/climber/jegk/ascents?page=3", http.requested.third
  end

  test "never walks past the hard cap" do
    http = FakeHttp.new([ FIXTURE ])

    scraper(http, pages: 999).call

    assert_operator http.requested.size, :<=, Imports::Thecrag::Scraper::MAX_PAGES
  end

  # Signed out, theCrag bounces the logbook to /home rather than erroring, which
  # used to look like an empty logbook.
  test "a bounce to /home is reported as an expired session" do
    http = FakeHttp.new([ "<html><body>home</body></html>" ], final_url: "https://www.thecrag.com/home")

    error = assert_raises(Imports::Thecrag::Scraper::SessionExpired) { scraper(http).call }
    assert_match(/no longer valid/, error.message)
  end

  # Walking a long logbook back to back earns a 429, so say that plainly rather
  # than reporting an empty logbook.
  test "a 429 is reported as rate limiting" do
    http = FakeHttp.new([ FIXTURE ], status: 429)

    error = assert_raises(Imports::Http::RateLimited) { scraper(http).call }
    assert_match(/rate limiting/, error.message)
  end

  test "paces itself between pages by default" do
    assert_operator Imports::Thecrag::Scraper::PAGE_PAUSE, :>, 0
  end

  test "accepts a bare session id or a full cookie header" do
    subject = scraper(FakeHttp.new([ FIXTURE ]))

    assert_equal "ApacheSessionID=abc123", subject.send(:normalized_cookie, "abc123")
    assert_equal "ApacheSessionID=abc123; other=1",
      subject.send(:normalized_cookie, "ApacheSessionID=abc123; other=1")
  end
end
