require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "service worker is served as javascript without signing in" do
    get pwa_service_worker_url

    assert_response :success
    assert_equal "text/javascript", response.media_type
  end

  # The build stamp is the entire update mechanism: it is what makes the
  # script bytes differ after a deploy, which is what gets the browser to
  # install a new worker and re-warm caches.
  test "service worker embeds the current build" do
    get pwa_service_worker_url

    assert_match(/const BUILD = "#{Regexp.escape(Rails.application.config.x.build_version)}"/, response.body)
  end

  test "service worker changes when the build changes" do
    get pwa_service_worker_url
    before = response.body

    with_build_version("some-other-sha") do
      get pwa_service_worker_url
      assert_not_equal before, response.body
    end
  end

  test "service worker embeds the digested core assets to precache" do
    get pwa_service_worker_url

    precached = JSON.parse(response.body[/const CORE_ASSETS = (\[.*?\])\n/m, 1])
    assert_equal Offline::Assets.urls, precached
  end

  # ERB output is HTML-escaped by default, which would emit &quot; and leave
  # the worker script unparseable.
  test "service worker is not html escaped" do
    get pwa_service_worker_url

    assert_no_match(/&quot;|&amp;|&#39;/, response.body)
  end

  private
    def with_build_version(version)
      original = Rails.application.config.x.build_version
      Rails.application.config.x.build_version = version
      yield
    ensure
      Rails.application.config.x.build_version = original
    end
end
