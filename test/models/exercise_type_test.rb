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
require "test_helper"

class ExerciseTypeTest < ActiveSupport::TestCase
  test "current_target returns the most recent target" do
    exercise_type = exercise_types(:running)
    assert_equal 45, exercise_type.current_target.value
  end

  test "current_target returns nil when no targets" do
    exercise_type = exercise_types(:deadhang)
    assert_nil exercise_type.current_target
  end

  test "chart_data_with_targets returns plain array when no exercise data" do
    exercise_type = exercise_types(:running)
    data = exercise_type.chart_data_with_targets

    # No exercises logged, so returns plain array (no target line without exercise data)
    assert data.is_a?(Array)
  end

  test "chart_data_with_targets returns plain array when no targets" do
    exercise_type = exercise_types(:deadhang)
    data = exercise_type.chart_data_with_targets

    assert data.is_a?(Array)
    assert data.empty? || !data.first.is_a?(Hash)
  end
end
