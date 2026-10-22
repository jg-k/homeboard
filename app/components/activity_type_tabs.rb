# The switcher across the top of the "Log Activity" pages. Each tab is its
# own new-record page, so switching replaces the history entry rather than
# stacking one per tap.
class ActivityTypeTabs < ApplicationComponent
  TABS = {
    exercise: { label: "Exercise", path: :new_exercise_path },
    gym_session: { label: "Indoor Climbing", path: :new_gym_session_path },
    hike: { label: "Hike", path: :new_hike_path }
  }.freeze

  def initialize(active:)
    @active = active
  end

  def view_template
    nav(class: "tabs", aria_label: "Activity type", data: { controller: "tabs" }) do
      TABS.each do |kind, tab|
        link_to public_send(tab[:path]),
                class: [ "tab", ("tab-active" if kind == @active) ],
                aria: { current: kind == @active ? "page" : nil },
                data: { turbo_action: "replace" } do
          tab_icon(kind)
          span { tab[:label] }
        end
      end
    end
  end

  private

  def tab_icon(kind)
    svg(class: "tab-icon", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
        stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
      case kind
      when :exercise
        s.line(x1: "2", y1: "12", x2: "22", y2: "12")
        s.rect(x: "4", y: "7", width: "3", height: "10", rx: "1")
        s.rect(x: "17", y: "7", width: "3", height: "10", rx: "1")
        s.rect(x: "1", y: "9", width: "3", height: "6", rx: "1")
        s.rect(x: "20", y: "9", width: "3", height: "6", rx: "1")
      when :gym_session
        s.rect(x: "4", y: "4", width: "4", height: "4", rx: "1")
        s.rect(x: "14", y: "6", width: "5", height: "3", rx: "1")
        s.rect(x: "6", y: "13", width: "5", height: "4", rx: "1")
        s.rect(x: "15", y: "15", width: "4", height: "4", rx: "1")
      when :hike
        s.path(d: "M8 3l4 8 5-5 5 15H2L8 3z")
      end
    end
  end
end
