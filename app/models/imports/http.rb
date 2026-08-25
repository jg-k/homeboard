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

  Response = Struct.new(:status, :body, :url, keyword_init: true) do
    def ok? = status == 200
  end

  def initialize(cookie: nil, timeout: 30)
    @cookie = cookie.presence
    @timeout = timeout
  end

  # Returns a Response. Follows redirects, but reports the URL it landed on so
  # callers can notice a bounce to a login or home page.
  def get(url)
    args = [
      "curl", "--silent", "--show-error", "--location",
      "--max-time", @timeout.to_s,
      "--user-agent", USER_AGENT,
      "--header", "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "--header", "Accept-Language: en-US,en;q=0.9",
      "--write-out", "\n%{http_code} %{url_effective}"
    ]
    args += [ "--cookie", @cookie ] if @cookie
    args << url

    out, err, status = Open3.capture3(*args)
    raise Error, "curl failed: #{err.presence || "exit #{status.exitstatus}"}" unless status.success?

    body, _, trailer = out.rpartition("\n")
    code, _, final_url = trailer.partition(" ")

    raise Blocked, "blocked by the site's bot protection (#{url})" if body.match?(BLOCK_MARKERS)

    Response.new(status: code.to_i, body: body, url: final_url)
  end
end
