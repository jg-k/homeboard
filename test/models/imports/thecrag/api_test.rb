require "test_helper"

class Imports::Thecrag::ApiTest < ActiveSupport::TestCase
  # Stands in for Imports::Http, recording what was asked for.
  class FakeHttp
    attr_reader :requested

    def initialize(pages, status: 200)
      @pages = pages
      @status = status
      @requested = []
    end

    def get(url)
      @requested << url
      @last = @pages.shift || @last
      body = @last
      body = body.to_json unless body.is_a?(String)
      Imports::Http::Response.new(status: @status, body: body, url: url)
    end
  end

  def payload(ascents, number: nil, per_page: 250)
    {
      "data" => {
        "account" => { "login" => "jegk" },
        "ascents" => ascents,
        "numberAscents" => number || ascents.size,
        "page" => "1",
        "perPage" => per_page
      }
    }
  end

  def ascent(overrides = {})
    {
      "id" => "9001",
      "epoch" => 1_771_193_431,
      "date" => "2026-06-01",
      "logDate" => "2026-06-02",
      "climbedGearStyle" => "sport",
      "tick" => { "label" => "redpoint", "name" => "Red point" },
      "markdown" => "Fought for it.",
      "route" => {
        "id" => "1234",
        "name" => "Magic Flute",
        "grade" => "7a",
        "stars" => 2,
        "height" => { "value" => 25, "unit" => "m" },
        "urlAncestorStub" => "/en/climbing/spain/siurana",
        "ancestors" => {
          "parent" => { "name" => "El Pati" },
          "country" => { "name" => "Spain" },
          "TLC" => { "name" => "Siurana" }
        }
      }
    }.merge(overrides)
  end

  def api(http, **options)
    Imports::Thecrag::Api.new("secret-key", http: http, pause: 0, **options)
  end

  test "maps an ascent onto the columns we store" do
    rows = api(FakeHttp.new([ payload([ ascent ]) ])).call

    assert_equal 1, rows.size
    row = rows.first
    assert_equal "9001", row.thecrag_ascent_id
    assert_equal "Magic Flute", row.route_name
    assert_equal "7a", row.grade
    assert_equal "redpoint", row.ascent_type
    assert_equal "sport", row.gear_style
    assert_equal "Siurana", row.crag_name
    assert_equal "/en/climbing/spain/siurana", row.crag_path
    assert_equal "Spain", row.country
    assert_equal 2, row.quality
    assert_equal 25, row.route_height
    assert_equal "Fought for it.", row.comment
    assert_equal 1_771_193_431, row.epoch
    assert_equal "1234", row.thecrag_route_id
    assert_equal Time.zone.parse("2026-06-01"), row.ascent_date
  end

  test "sends the key as a header rather than a query parameter" do
    http = FakeHttp.new([ payload([ ascent ]) ])
    subject = Imports::Thecrag::Api.new("secret-key", pause: 0)

    headers = subject.instance_variable_get(:@http).instance_variable_get(:@headers)
    assert_equal "key=secret-key", headers["X-CData-Key"]
    assert_equal "application/json", headers["Accept"]

    api(http).call
    assert_no_match(/secret-key/, http.requested.first)
  end

  # The whole point of the key: a repeat sync spends the smallest number of
  # tokens it can by asking only for what changed.
  test "asks only for ascents newer than the given epoch" do
    http = FakeHttp.new([ payload([]) ])

    api(http, since: 1_771_193_431).call

    assert_equal "#{Imports::Thecrag::Api::ENDPOINT}?since=1771193431", http.requested.first
  end

  test "a first sync asks for the whole logbook" do
    http = FakeHttp.new([ payload([ ascent ]) ])

    api(http).call

    assert_equal Imports::Thecrag::Api::ENDPOINT, http.requested.first
  end

  test "walks every page the total implies" do
    http = FakeHttp.new([
      payload([ ascent("id" => "1") ], number: 3, per_page: 1),
      payload([ ascent("id" => "2") ], number: 3, per_page: 1),
      payload([ ascent("id" => "3") ], number: 3, per_page: 1)
    ])

    rows = api(http).call

    assert_equal 3, http.requested.size
    assert_equal %w[1 2 3], rows.map(&:thecrag_ascent_id)
    assert_match(/page=2/, http.requested.second)
  end

  test "carries the since parameter onto later pages" do
    http = FakeHttp.new([
      payload([ ascent("id" => "1") ], number: 2, per_page: 1),
      payload([ ascent("id" => "2") ], number: 2, per_page: 1)
    ])

    api(http, since: 42).call

    assert_match(/since=42/, http.requested.second)
  end

  test "stops at the hard page cap" do
    http = FakeHttp.new([ payload([ ascent ], number: 100_000, per_page: 1) ])

    api(http).call

    assert_operator http.requested.size, :<=, Imports::Thecrag::Api::MAX_PAGES
  end

  # The watermark hangs on this: a read that stopped at the cap has the newest
  # ascents and none of the oldest, and must not be remembered as complete.
  test "says so when the page cap cut the read short" do
    reader = api(FakeHttp.new([ payload([ ascent ], number: 100_000, per_page: 1) ]))
    reader.call

    assert reader.truncated?
  end

  test "a logbook read to the end is not truncated" do
    reader = api(FakeHttp.new([ payload([ ascent ]) ]))
    reader.call

    assert_not reader.truncated?
  end

  # theCrag said there were more pages, so a page we could make nothing of is
  # not the end of the logbook.
  test "keeps paging past a page of ascents it cannot use" do
    http = FakeHttp.new([
      payload([ ascent("id" => "1") ], number: 3, per_page: 1),
      payload([ ascent("id" => nil, "date" => nil, "logDate" => nil) ], number: 3, per_page: 1),
      payload([ ascent("id" => "3") ], number: 3, per_page: 1)
    ])

    rows = api(http).call

    assert_equal 3, http.requested.size
    assert_equal %w[1 3], rows.map(&:thecrag_ascent_id)
  end

  test "JSON that is not an object is an error rather than a crash" do
    http = FakeHttp.new([ "[]" ])

    error = assert_raises(Imports::Thecrag::Api::Error) { api(http).call }
    assert_match(/do not recognise/, error.message)
  end

  test "a rejected key says so rather than looking like an empty logbook" do
    http = FakeHttp.new([ { "error" => "forbidden" } ], status: 403)

    error = assert_raises(Imports::Thecrag::Api::InvalidKey) { api(http).call }
    assert_match(/rejected the API key/, error.message)
  end

  test "an exhausted token budget is named as such" do
    http = FakeHttp.new([ { "error" => "budget" } ], status: 429)

    error = assert_raises(Imports::Thecrag::Api::BudgetExhausted) { api(http).call }
    assert_match(/token budget/, error.message)
  end

  test "refuses to call without a key" do
    assert_raises(ArgumentError) { Imports::Thecrag::Api.new("", pause: 0).call }
  end

  test "skips ascents with no usable date" do
    rows = api(FakeHttp.new([ payload([ ascent("date" => nil, "logDate" => nil) ]) ])).call

    assert_empty rows
  end

  # The shape theCrag actually sends, and the one that used to take the whole
  # import down with it: a pair, with the number arriving as a string.
  test "reads a height sent as a value and unit pair" do
    rows = api(FakeHttp.new([
      payload([ ascent.deep_merge("route" => { "height" => [ "514", "m" ] }) ])
    ])).call

    assert_equal 514, rows.first.route_height
  end

  test "totals a height broken down by pitch" do
    rows = api(FakeHttp.new([
      payload([ ascent.deep_merge("route" => { "height" => [ { "value" => 20, "unit" => "m" }, { "value" => 25, "unit" => "m" } ] }) ])
    ])).call

    assert_equal 45, rows.first.route_height
  end

  # One route with a field we have never seen must not cost us the other 468.
  test "a height in no shape we know leaves the column empty" do
    unknown = ascent["route"].merge("height" => { "metres" => 20 })
    rows = api(FakeHttp.new([ payload([ ascent.merge("route" => unknown) ]) ])).call

    assert_equal 1, rows.size
    assert_nil rows.first.route_height
  end

  test "converts a height reported in feet" do
    rows = api(FakeHttp.new([
      payload([ ascent.deep_merge("route" => { "height" => { "value" => 100, "unit" => "ft" } }) ])
    ])).call

    assert_equal 30, rows.first.route_height
  end

  test "leaves a tick type we have no column for unset" do
    rows = api(FakeHttp.new([ payload([ ascent("tick" => { "label" => "somethingnew" }) ]) ])).call

    assert_nil rows.first.ascent_type
  end

  test "paces itself between pages by default" do
    assert_operator Imports::Thecrag::Api::PAGE_PAUSE, :>, 0
  end
end
