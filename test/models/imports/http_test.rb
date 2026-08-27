require "test_helper"

class Imports::HttpTest < ActiveSupport::TestCase
  Status = Struct.new(:ok) do
    def success? = ok
    def exitstatus = ok ? 0 : 1
  end

  # Stands in for Open3, which Imports::Http finds through Object, so the curl
  # invocation can be inspected without running one.
  module Curl
    singleton_class.attr_accessor :body, :args, :stdin

    def self.capture3(*args, **options)
      self.args = args
      self.stdin = options[:stdin_data]

      [ "#{body}\n200 https://www.thecrag.com/", "", Status.new(true) ]
    end
  end

  def get(body, **options)
    Curl.body = body
    Curl.args = nil
    Curl.stdin = nil

    stub_const(Object, :Open3, Curl) do
      Imports::Http.new(**options).get("https://www.thecrag.com/")
    end
  end

  test "an HTML interstitial is a block" do
    assert_raises(Imports::Http::Blocked) do
      get("<html><head><title>Just a moment...</title></head></html>")
    end
  end

  # The API path feeds this the climber's own ascent notes. Reading one as a
  # Cloudflare page would fail their sync on every later attempt too.
  test "a JSON body that reads like an interstitial is not a block" do
    body = { "ascents" => [ { "markdown" => "just a moment of panic on the crux" } ] }.to_json

    assert_equal body, get(body).body
  end

  test "the credential goes over stdin rather than the argument list" do
    get("{}", headers: { "X-CData-Key" => "key=secret" })

    assert_no_match(/secret/, Curl.args.join(" "))
    assert_includes Curl.stdin, %(header = "X-CData-Key: key=secret")
  end

  test "a cookie goes the same way" do
    get("<html></html>", cookie: "session=abc123")

    assert_no_match(/abc123/, Curl.args.join(" "))
    assert_includes Curl.stdin, %(cookie = "session=abc123")
  end

  test "a quote in a header value cannot break out of the config" do
    get("{}", headers: { "X-Test" => %(a"b\\c) })

    assert_includes Curl.stdin, %(header = "X-Test: a\\"b\\\\c")
  end

  test "follows redirects by default and not when told otherwise" do
    get("{}")
    assert_includes Curl.args, "--location"

    get("{}", follow_redirects: false)
    assert_not_includes Curl.args, "--location"
  end
end
