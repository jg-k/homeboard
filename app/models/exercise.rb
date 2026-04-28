class Exercise < ApplicationRecord
  belongs_to :exercise_type

  has_one :activity_log, as: :loggable, dependent: :destroy

  validates :value, presence: true

  attr_accessor :performed_at

  after_create :create_activity_log_entry

  delegate :name, :unit, :user, :rest_seconds, to: :exercise_type

  def effective_reps
    reps.presence || exercise_type.reps
  end

  private

  def create_activity_log_entry
    create_activity_log!(user: user, performed_at: performed_at || Time.current)
  end
end

# == Schema Information
#
# Table name: exercises
#
#  id               :integer          not null, primary key
#  added_weight     :decimal(, )
#  notes            :text
#  reps             :integer
#  rpe              :decimal(, )
#  value            :decimal(, )
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  exercise_type_id :integer          not null
#
# Indexes
#
#  index_exercises_on_exercise_type_id  (exercise_type_id)
#
# Foreign Keys
#
#  exercise_type_id  (exercise_type_id => exercise_types.id)
#
