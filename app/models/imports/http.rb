require "open3"

# Fetches pages through the curl binary rather than Net::HTTP.
#
# This is not stylistic. Cloudflare fingerprints the TLS handshake: from this
# machine, curl gets HTTP 200 from thecrag.com while Net::HTTP gets 403 with
# identical headers, cookie and IP, on both HTTP/1.1 and HTTP/2. A headless
# browser fares worse still -- it is hard-blocked by the WAF -- which is why
# there is no browser here any more.
class Imports::Http
  class Error < StandardError; end
  class Blocked < Error; end
  class RateLimited < Error; end

  USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
               "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36".freeze

  BLOCK_MARKERS = /just a moment|attention required|sorry, you have been blocked/i

  DEFAULT_HEADERS = {
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language" => "en-US,en;q=0.9"
  }.freeze

  Response = Struct.new(:status, :body, :url, keyword_init: true) do
    def ok? = status == 200
  end

  # Turn following off when the headers carry a credential: curl re-sends custom
  # headers to whatever host it is redirected to.
  def initialize(cookie: nil, timeout: 30, headers: {}, follow_redirects: true)
    @cookie = cookie.presence
    @timeout = timeout
    @headers = DEFAULT_HEADERS.merge(headers)
    @follow_redirects = follow_redirects
  end

  # Returns a Response. Reports the URL it landed on so callers can notice a
  # bounce to a login or home page.
  def get(url)
    args = [
      "curl", "--silent", "--show-error",
      "--max-time", @timeout.to_s,
      "--user-agent", USER_AGENT,
      "--write-out", "\n%{http_code} %{url_effective}",
      # Headers and cookies over stdin, not argv, where `ps` would show the key.
      "--config", "-"
    ]
    args << "--location" if @follow_redirects
    args << url

    out, err, status = Open3.capture3(*args, stdin_data: curl_config)
    raise Error, "curl failed: #{err.presence || "exit #{status.exitstatus}"}" unless status.success?

    body, _, trailer = out.rpartition("\n")
    code, _, final_url = trailer.partition(" ")

    raise Blocked, "blocked by the site's bot protection (#{url})" if blocked?(body)

    Response.new(status: code.to_i, body: body, url: final_url)
  end

  private

  # curl's config syntax: one option per line, values double quoted with
  # backslash escapes. A newline in a value would end the option early.
  def curl_config
    lines = @headers.map { |name, value| "header = #{quote("#{name}: #{value}")}" }
    lines << "cookie = #{quote(@cookie)}" if @cookie
    lines.join("\n") + "\n"
  end

  def quote(value)
    %("#{value.to_s.delete("\r\n").gsub(/[\\"]/) { |char| "\\#{char}" }}")
  end

  # Interstitials are HTML. The same words in a JSON body are a climber's own
  # ascent note -- "just a moment of panic on the crux" -- not Cloudflare.
  def blocked?(body)
    body.lstrip.start_with?("<") && body.match?(BLOCK_MARKERS)
  end
end
