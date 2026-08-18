require "test_helper"

class Offline::AssetsTest < ActiveSupport::TestCase
  setup do
    @urls = Offline::Assets.urls
  end

  test "includes every same-origin importmap module" do
    imports = JSON.parse(Rails.application.importmap.to_json(resolver: ActionController::Base.helpers))
      .fetch("imports").values
    same_origin = imports.grep_v(%r{\A(https?:)?//})

    assert_predicate same_origin, :any?
    assert_empty same_origin - @urls
  end

  test "excludes CDN-hosted modules the service worker cannot cache same-origin" do
    assert_empty @urls.grep(%r{\Ahttps?://})
  end

  test "includes the digested app stylesheet" do
    assert_includes @urls, ActionController::Base.helpers.stylesheet_path("application.css")
  end

  test "includes the nav logo" do
    assert_includes @urls, ActionController::Base.helpers.asset_path("crimp_white.svg")
  end

  test "includes the PWA icons" do
    assert_includes @urls, "/icon.png"
    assert_includes @urls, "/icon.svg"
  end

  # Engine assets are namespaced under a directory and are dead weight on a
  # phone that will never open the jobs dashboard offline.
  test "excludes engine assets" do
    assert_empty @urls.grep(%r{/assets/mission_control/})
  end

  # Bitmaps are megabytes; the only images worth caching are board layout
  # photos, which the pin flow handles per board.
  test "excludes bitmaps" do
    assert_empty @urls.grep(/\.(png|jpe?g)\z/).reject { |url| url.start_with?("/icon.") }
  end

  test "has no duplicates" do
    assert_equal @urls, @urls.uniq
  end
end
