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
      render_comments
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

  def render_comments
    comments = @activity_log.comments.to_a
    return if comments.empty?

    div(class: "activity-comments") do
      comments.each do |comment|
        div(class: "activity-comment") do
          render Badge.new(ActivityLogComment.category_badge_color(comment.category)) do
            plain ActivityLogComment.category_label(comment.category)
          end
          span(class: "activity-comment-body") { comment.body }
          unless @readonly
            div(class: "activity-comment-actions") do
              link_to edit_activity_log_comment_path(@activity_log, comment),
                      class: "btn-icon",
                      title: "Edit comment",
                      data: { turbo_frame: "_top" } do
                icon(:edit, size: :sm)
              end
              button_to activity_log_comment_path(@activity_log, comment),
                        method: :delete,
                        class: "btn-icon-danger",
                        title: "Delete comment",
                        data: { turbo_confirm: "Delete this comment?", turbo_frame: "_top" } do
                icon(:trash, size: :sm)
              end
            end
          end
        end
      end
    end
  end
end
