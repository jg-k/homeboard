class ActivityCard < ApplicationComponent
  REGISTRY = {
    "BoardClimb" => "BoardClimbCard",
    "Exercise" => "ExerciseCard",
    "GymSession" => "GymSessionCard",
    "CragAscent" => "CragAscentCard",
    "SystemBoardClimb" => "SystemBoardClimbCard",
    "Hike" => "HikeCard"
  }.freeze

  def self.for(activity_log:, **)
    REGISTRY.fetch(activity_log.loggable_type).constantize.new(activity_log: activity_log, **)
  end

  def initialize(activity_log:, loggable: nil, readonly: false, **)
    @activity_log = activity_log
    @loggable = loggable
    @readonly = readonly
  end

  def view_template
    div(class: "card card-bordered card-#{kind} activity-card") do
      div(class: "flex-between") do
        div do
          div(class: "activity-header") do
            render Badge.new(badge_color) { badge_label }
            render_header
          end
          div(class: "activity-meta") { render_meta }
          div(class: "activity-notes") { simple_format(notes) } if notes.present?
        end
        if !@readonly && (actions = activity_actions)
          render actions
        end
      end
    end
  end

  private

  def loggable = @loggable || @activity_log.loggable
  def kind = raise NotImplementedError
  def badge_color = :gray
  def badge_label = raise NotImplementedError
  def render_header = raise NotImplementedError
  def render_meta = raise NotImplementedError
  def notes = nil
  def activity_actions = nil
end
