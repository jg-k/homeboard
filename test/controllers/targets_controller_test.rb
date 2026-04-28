require "test_helper"

class TargetsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @exercise_type = exercise_types(:running)
    sign_in @user
  end

  test "should create target for exercise type" do
    assert_difference("Target.count") do
      post exercise_type_targets_url(@exercise_type), params: {
        target: { value: 60, applicable_from: Time.current }
      }
    end

    assert_response :redirect
    assert_equal "Target set", flash[:notice]
  end

  test "should not allow creating target for another users exercise type" do
    other_user = users(:two)
    other_exercise_type = ExerciseType.create!(name: "Other", unit: "reps", user: other_user)

    assert_no_difference("Target.count") do
      post exercise_type_targets_url(other_exercise_type), params: { target: { value: 60 } }
    end

    assert_response :not_found
  end
end
