class ExerciseType < ApplicationRecord
  belongs_to :user

  has_many :exercises, dependent: :destroy
  has_many :targets, as: :targetable, dependent: :destroy

  enum :category, {
    core: "core",
    upper_body: "upper_body",
    finger: "finger",
    lower_body: "lower_body",
    cardio: "cardio",
    other: "other"
  }, default: :other

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :unit, presence: true

  attr_accessor :initial_target

  def chart_data
    if added_weight_possible? && has_varying_reps?
      rows = exercises.joins(:activity_log)
                      .order("activity_logs.performed_at")
                      .pluck("activity_logs.performed_at", :value, :added_weight, :reps)

      rows.group_by do |_, _, aw, r|
        weight = aw.present? ? "+#{aw.to_i}kg" : "Bodyweight"
        "#{weight} × #{r.presence || reps} reps"
      end.map { |label, entries| { name: label, data: entries.map { |p, v, _, _| [ p.to_date.iso8601, v.to_f ] } } }
    elsif added_weight_possible?
      rows = exercises.joins(:activity_log)
                      .order("activity_logs.performed_at")
                      .pluck("activity_logs.performed_at", :value, :added_weight)

      rows.group_by { |_, _, aw| aw.present? ? "+#{aw.to_i}kg" : "Bodyweight" }
          .map { |label, entries| { name: label, data: entries.map { |p, v, _| [ p.to_date.iso8601, v.to_f ] } } }
    elsif has_varying_reps?
      rows = exercises.joins(:activity_log)
                      .order("activity_logs.performed_at")
                      .pluck("activity_logs.performed_at", :value, :reps)

      rows.group_by { |_, _, r| "#{r.presence || reps} reps" }
          .map { |label, entries| { name: label, data: entries.map { |p, v, _| [ p.to_date.iso8601, v.to_f ] } } }
    else
      exercises.joins(:activity_log)
               .order("activity_logs.performed_at")
               .pluck("activity_logs.performed_at", :value)
               .map { |performed_at, value| [ performed_at.to_date.iso8601, value.to_f ] }
    end
  end

  def current_target
    targets.first # returns most recent due to default_scope
  end

  def chart_data_with_targets
    exercise_data = chart_data

    # When chart_data returns multiple series (added weight grouping), use flat data for target staircase
    if exercise_data.is_a?(Array) && exercise_data.first.is_a?(Hash)
      flat_data = exercise_data.flat_map { |s| s[:data] }.sort_by(&:first)
      target_data = build_target_staircase(flat_data)
      target_data.empty? ? exercise_data : exercise_data + [ { name: "Target", data: target_data } ]
    else
      target_data = build_target_staircase(exercise_data)
      return exercise_data if target_data.empty?

      [
        { name: name, data: exercise_data },
        { name: "Target", data: target_data }
      ]
    end
  end

  def has_varying_reps?
    exercises.where.not(reps: nil).where.not(reps: reps).exists?
  end

  private

  def build_target_staircase(exercise_data)
    sorted_targets = targets.reorder(applicable_from: :asc)
    return [] if sorted_targets.empty? || exercise_data.empty?

    today = Date.current
    data = []

    # Only include targets up to today
    applicable_targets = sorted_targets.select { |t| t.applicable_from.to_date <= today }
    return [] if applicable_targets.empty?

    # Get exercise data date range
    exercise_start = Date.parse(exercise_data.first.first)

    applicable_targets.each_with_index do |target, index|
      target_date = target.applicable_from.to_date

      # For the first target, extend back to the start of exercise data if earlier
      if index == 0 && exercise_start < target_date
        data << [ exercise_start.to_datetime.beginning_of_day.iso8601, target.value.to_f ]
      end

      # Add point just before new target (with old value) to create step
      if index > 0
        prev_value = applicable_targets[index - 1].value.to_f
        just_before = target_date.to_datetime.beginning_of_day - 1.minute
        data << [ just_before.iso8601, prev_value ]
      end

      # Add the new target value
      data << [ target_date.to_datetime.beginning_of_day.iso8601, target.value.to_f ]
    end

    # Extend to today
    last_date = Date.parse(data.last.first.to_s[0..9])
    data << [ today.to_datetime.end_of_day.iso8601, applicable_targets.last.value.to_f ] if last_date < today

    data
  end
end

# == Schema Information
#
# Table name: exercise_types
#
#  id                    :integer          not null, primary key
#  added_weight_possible :boolean          default(FALSE), not null
#  category              :string           default("other"), not null
#  name                  :string           not null
#  reps                  :integer
#  rest_seconds          :integer
#  unit                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :integer          not null
#
# Indexes
#
#  index_exercise_types_on_user_id           (user_id)
#  index_exercise_types_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
