# A row of links where one is the current choice, such as a chart's
# look-back period. Choices live in the query string, so each option is a
# plain link and switching replaces the history entry.
class SegmentedControl < ApplicationComponent
  Option = Data.define(:label, :url, :active)

  def initialize(label:, options:)
    @label = label
    @options = options
  end

  def view_template
    nav(class: "period-picker", aria_label: @label) do
      @options.each do |option|
        link_to option.label, option.url,
                class: [ "period-picker-option", ("period-picker-active" if option.active) ],
                aria: { current: option.active || nil },
                data: { turbo_action: "replace" }
      end
    end
  end
end
