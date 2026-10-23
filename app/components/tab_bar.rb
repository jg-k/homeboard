# The one tab row the app uses, from the Log Activity switcher to the stats
# categories. A second row nested under another passes secondary: true to
# step down a size, so the two levels still read apart.
#
# Tabs are plain links; by default switching replaces the history entry, as
# tabs over one page should. Pass replace: false where each tab is a place
# worth going back to, such as a board.
class TabBar < ApplicationComponent
  Tab = Data.define(:label, :url, :active)

  def initialize(label:, tabs:, secondary: false, replace: true)
    @label = label
    @tabs = tabs
    @secondary = secondary
    @replace = replace
  end

  def view_template
    nav(class: [ "tabs", ("tabs-secondary" if @secondary) ], aria_label: @label, data: { controller: "tabs" }) do
      @tabs.each do |tab|
        link_to tab.label, tab.url,
                class: [ "tab", ("tab-active" if tab.active) ],
                aria: { current: tab.active ? "page" : nil },
                data: { turbo_action: ("replace" if @replace) }
      end
    end
  end
end
