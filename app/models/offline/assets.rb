module Offline
  # The digested asset URLs a pinned page needs to render with no network:
  # every same-origin importmap module, the app stylesheets, and the SVGs.
  #
  # The service worker precaches these on activation. It has to, because a
  # deploy rewrites every digest: the freshly cached HTML points at asset URLs
  # that nothing has fetched yet, and discovering that while offline means a
  # pinned page renders unstyled with no Stimulus.
  #
  # Bitmaps are deliberately excluded — they're megabytes, and the only images
  # that matter offline are the board layout photos, which the pin flow caches
  # per board.
  class Assets
    ICONS = %w[ /icon.png /icon.svg ].freeze

    def self.urls
      new.urls
    end

    def urls
      (importmap_modules + stylesheets + vectors + ICONS).uniq
    end

    private
      def importmap_modules
        imports = JSON.parse(Rails.application.importmap.to_json(resolver: helpers)).fetch("imports", {})
        imports.values.grep_v(%r{\A(https?:)?//})
      end

      def stylesheets
        own_asset_paths("css").map { |path| helpers.stylesheet_path(path) }
      end

      def vectors
        own_asset_paths("svg").map { |path| helpers.asset_path(path) }
      end

      # Top-level logical paths only. Engine assets are namespaced under a
      # directory (mission_control/jobs/…) and none of them are needed offline.
      def own_asset_paths(extension)
        Rails.application.assets.load_path.asset_paths_by_type(extension)
          .reject { |path| path.include?("/") }
      end

      def helpers
        ActionController::Base.helpers
      end
  end
end
