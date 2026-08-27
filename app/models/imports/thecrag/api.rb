require "json"

# Reads a climber's logbook through theCrag's personal API key endpoint.
# https://www.thecrag.com/en/article/logbookreadapi
#
# Supporters issue themselves a key under Settings > API Keys; it grants read
# access to that one logbook and nobody else's. This beats the scraper in every
# way that matters: no borrowed admin session, no HTML to guess at, and the
# whole history is available rather than the first page.
#
# What it costs instead is tokens. Every call spends from a weekly budget theCrag
# does not disclose, so we never re-read the logbook wholesale: each ascent
# carries an `epoch` -- when it was created or last edited -- and passing the
# highest one back as `since` asks only for what changed.
class Imports::Thecrag::Api
  class Error < Imports::Http::Error; end
  # The key was revoked, has outlived its maximum lifetime, or its owner's
  # supporter status lapsed. All three are the user's to fix, not ours to retry.
  class InvalidKey < Error; end
  # The account's weekly token budget is gone until it resets.
  class BudgetExhausted < Error; end

  Row = Imports::Thecrag::Row

  ENDPOINT = "https://www.thecrag.com/api/logbook/ascents"

  # theCrag's own page size; asking for more is not an option.
  PER_PAGE = 250

  # A logbook of 10,000 ascents is 40 pages. Nobody's first sync should cost
  # more than that, and a runaway pager would eat the weekly budget in one go.
  MAX_PAGES = 40

  PAGE_PAUSE = 1.0

  # `since` is an epoch: pass the highest one seen on the previous sync and the
  # API returns only ascents created or updated after it.
  def initialize(api_key, since: nil, http: nil, pause: PAGE_PAUSE)
    @api_key = api_key.to_s.strip
    @since = since.presence
    @pause = pause
    @truncated = false
    @http = http || Imports::Http.new(follow_redirects: false, headers: {
      "Accept" => "application/json",
      "X-CData-Key" => "key=#{@api_key}"
    })
  end

  # True when the page cap stopped us short of the whole logbook.
  def truncated? = @truncated

  def call
    raise ArgumentError, "a theCrag API key is required" if @api_key.blank?

    rows = []
    page = 1
    @truncated = false

    loop do
      body = fetch(page)
      ascents = body.fetch("ascents", [])
      rows.concat(ascents.filter_map { |ascent| build_row(ascent) })

      # Measured on what theCrag sent, not on what survived build_row: a page of
      # ascents we cannot read is not the end of the logbook.
      break if ascents.empty?

      pages = last_page(body)
      if page >= MAX_PAGES
        @truncated = pages > MAX_PAGES
        break
      end
      break if page >= pages

      page += 1
      sleep @pause if @pause.to_f.positive?
    end

    rows
  end

  private

  def fetch(page)
    response = @http.get(url_for(page))

    raise InvalidKey, "theCrag rejected the API key (HTTP #{response.status})" if [ 401, 403 ].include?(response.status)
    if response.status == 429
      raise BudgetExhausted,
            "theCrag's weekly API token budget is exhausted (HTTP 429). It resets once a week."
    end
    raise Error, "theCrag returned HTTP #{response.status}" unless response.ok?

    parsed = JSON.parse(response.body)
    body = parsed.is_a?(Hash) && parsed["data"].is_a?(Hash) ? parsed["data"] : parsed
    raise Error, "theCrag returned JSON we do not recognise (a #{body.class})" unless body.is_a?(Hash)

    body
  rescue JSON::ParserError => e
    raise Error, "theCrag returned something that is not JSON: #{e.message}"
  end

  def url_for(page)
    params = {}
    params[:page] = page if page > 1
    params[:since] = @since if @since
    return ENDPOINT if params.empty?

    "#{ENDPOINT}?#{params.to_query}"
  end

  # The payload counts the whole logbook, not the page, so the last page is
  # whatever that total divides into.
  def last_page(body)
    total = body["numberAscents"].to_i
    per_page = body["perPage"].to_i
    per_page = PER_PAGE unless per_page.positive?

    total.positive? ? (total.to_f / per_page).ceil : 1
  end

  def build_row(ascent)
    id = ascent["id"].presence
    date = parse_date(ascent["date"] || ascent["logDate"])
    return nil unless id && date

    route = ascent["route"] || {}

    Row.new(
      thecrag_ascent_id: id.to_s,
      thecrag_route_id: route["id"].presence&.to_s,
      ascent_date: date,
      route_name: route["name"].presence,
      grade: route["grade"].presence,
      ascent_type: Imports::Thecrag::TICK_LABEL_MAP[tick_label(ascent)],
      gear_style: gear_style(ascent, route),
      crag_name: ancestor(route, "TLC")["name"].presence || ancestor(route, "parent")["name"].presence,
      crag_path: route["urlAncestorStub"].presence,
      country: ancestor(route, "country")["name"].presence,
      quality: route["stars"].to_i.positive? ? route["stars"].to_i : nil,
      route_height: height_in_metres(route["height"]),
      comment: ascent["markdown"].presence,
      epoch: ascent["epoch"]&.to_i
    )
  end

  def tick_label(ascent)
    tick = ascent["tick"]
    label = tick.is_a?(Hash) ? tick["label"] : tick
    label.to_s.downcase.delete(" _-").presence
  end

  # `climbedGearStyle` is how the climber did it, which is what we want; the
  # route's own style is the fallback for logbooks that predate the field.
  def gear_style(ascent, route)
    value = ascent["climbedGearStyle"].presence || route["style"].presence
    Imports::Thecrag::GEAR_STYLE_MAP[value.to_s.capitalize]
  end

  def ancestor(route, key)
    ancestors = route["ancestors"]
    return {} unless ancestors.is_a?(Hash)

    ancestors[key].is_a?(Hash) ? ancestors[key] : {}
  end

  # Height arrives as a bare number of metres, a value/unit pair, or a list --
  # one entry per pitch on a multi-pitch route, which totals to the climb. Any
  # other shape is not a height: losing the column beats losing the ascent.
  def height_in_metres(height)
    metres = metres_in(height)
    metres&.positive? ? metres.round : nil
  end

  def metres_in(height)
    case height
    when Numeric then height.to_f
    when String then height.to_f
    when Hash then converted(height["value"], height["unit"])
    when Array then pitch_total(height)
    end
  end

  # A pair reads as one height, anything longer as a pitch-by-pitch breakdown.
  def pitch_total(height)
    return converted(height.first, height.second) if height.size == 2 && height.second.is_a?(String)

    total = height.filter_map { |pitch| metres_in(pitch) }.sum
    total.positive? ? total : nil
  end

  def converted(value, unit)
    metres = value.to_f
    metres *= 0.3048 if unit.to_s.downcase.start_with?("f")
    metres
  end

  def parse_date(string)
    return nil if string.blank?

    Time.zone.parse(string.to_s)
  rescue ArgumentError
    nil
  end
end
