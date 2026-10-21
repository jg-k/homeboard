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

  def has_varying_reps?
    exercises.where.not(reps: nil).where.not(reps: reps).exists?
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
