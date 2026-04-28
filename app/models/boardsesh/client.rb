require "net/http"
require "json"
require "uri"

class Boardsesh::Client
  BASE_URL = "https://www.boardsesh.com".freeze
  GRAPHQL_ENDPOINT = "https://ws.boardsesh.com/graphql".freeze

  SUPPORTED_BOARDS = %w[kilter tension].freeze

  class AuthenticationError < StandardError; end
  class ApiError < StandardError; end

  FETCH_ASCENTS_QUERY = <<~GRAPHQL.freeze
    query UserAscentsFeed($userId: ID!, $input: AscentFeedInput) {
      userAscentsFeed(userId: $userId, input: $input) {
        items {
          uuid
          climbUuid
          climbName
          setterUsername
          boardType
          layoutId
          angle
          isMirror
          status
          attemptCount
          quality
          difficulty
          difficultyName
          consensusDifficultyName
          isBenchmark
          comment
          climbedAt
        }
        totalCount
        hasMore
      }
    }
  GRAPHQL

  def initialize(session_token: nil)
    @session_token = session_token
  end

  def login(email:, password:)
    csrf_uri = URI("#{BASE_URL}/api/auth/csrf")
    csrf_response = perform_request(csrf_uri, Net::HTTP::Get.new(csrf_uri))
    raise ApiError, "Failed to get CSRF token: #{csrf_response.code}" unless csrf_response.is_a?(Net::HTTPSuccess)

    csrf_data = JSON.parse(csrf_response.body)
    csrf_token = csrf_data["csrfToken"]
    cookies = extract_cookies(csrf_response)

    auth_uri = URI("#{BASE_URL}/api/auth/callback/credentials")
    auth_request = Net::HTTP::Post.new(auth_uri)
    auth_request["Content-Type"] = "application/x-www-form-urlencoded"
    auth_request["Cookie"] = cookies

    auth_request.body = URI.encode_www_form(
      csrfToken: csrf_token,
      email: email,
      password: password
    )

    auth_response = perform_request(auth_uri, auth_request, follow_redirects: true)
    session_cookie = extract_session_token(auth_response)
    raise AuthenticationError, "Invalid email or password" unless session_cookie

    @session_token = session_cookie

    profile = fetch_profile
    raise AuthenticationError, "Could not fetch profile after login" unless profile

    {
      session_token: @session_token,
      user_id: profile["id"],
      email: profile["email"],
      name: profile["name"]
    }
  end

  def fetch_profile
    uri = URI("#{BASE_URL}/api/internal/profile")
    request = Net::HTTP::Get.new(uri)
    request["Cookie"] = session_cookie_header

    response = perform_request(uri, request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def fetch_ascents(user_id, since: nil, limit: 50, offset: 0, board_types: SUPPORTED_BOARDS)
    input = {
      boardTypes: board_types,
      limit: limit,
      offset: offset,
      sortBy: "recent",
      sortOrder: "desc"
    }
    input[:fromDate] = since.iso8601 if since

    body = graphql_post(FETCH_ASCENTS_QUERY, userId: user_id, input: input)
    body.dig("data", "userAscentsFeed") || { "items" => [], "hasMore" => false }
  end

  def fetch_all_ascents(user_id, since: nil, board_types: SUPPORTED_BOARDS)
    results = []
    offset = 0
    loop do
      page = fetch_ascents(user_id, since: since, offset: offset, board_types: board_types)
      items = page["items"] || []
      results.concat(items)
      break unless page["hasMore"] && items.any?
      offset += items.size
    end
    results
  end

  private

  def graphql_post(query, variables = {})
    uri = URI(GRAPHQL_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = { query: query, variables: variables }.to_json

    response = perform_request(uri, request)
    raise ApiError, "GraphQL request failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    if body["errors"]
      messages = body["errors"].map { |e| e["message"] }.join("; ")
      raise ApiError, "Boardsesh GraphQL error: #{messages}"
    end
    body
  end

  def session_cookie_header
    "__Secure-next-auth.session-token=#{@session_token}"
  end

  def extract_cookies(response)
    response.get_fields("set-cookie")&.map { |c| c.split(";").first }&.join("; ") || ""
  end

  def extract_session_token(response)
    cookies = response.get_fields("set-cookie") || []
    cookies.each do |cookie|
      if cookie.include?("__Secure-next-auth.session-token=")
        return cookie.match(/__Secure-next-auth\.session-token=([^;]+)/)[1]
      end
    end
    nil
  end

  def perform_request(uri, request, follow_redirects: false)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30
    http.read_timeout = 120

    response = http.request(request)

    if follow_redirects && response.is_a?(Net::HTTPRedirection)
      location = response["location"]
      redirect_uri = location.start_with?("http") ? URI(location) : URI("#{BASE_URL}#{location}")
      redirect_request = Net::HTTP::Get.new(redirect_uri)
      all_cookies = extract_cookies(response)
      redirect_request["Cookie"] = all_cookies if all_cookies.present?
      return perform_request(redirect_uri, redirect_request)
    end

    response
  end
end
