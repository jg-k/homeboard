require "test_helper"

class ExerciseTypes::TimersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @hang = @user.exercise_types.create!(name: "Max hang", unit: "seconds", added_weight_possible: true, reps: 5, rest_seconds: 120)
  end

  test "starts from the exercise type's reps and rest" do
    get exercise_type_timer_path(@hang)

    assert_response :success
    assert_select "[data-controller=interval-timer]"
    assert_select "input[name='exercise[value]'][data-interval-timer-target=work][value='10']"
    assert_select "input[name='exercise[reps]'][value='5']"
    assert_select "input#timer_rest:not([name])[value='120']"
  end

  test "starts from the last set logged" do
    @hang.exercises.create!(value: 7, reps: 6, added_weight: 15, performed_at: 2.days.ago)
    @hang.exercises.create!(value: 10, reps: 4, added_weight: 20, performed_at: 1.day.ago)

    get exercise_type_timer_path(@hang)

    assert_select "input[name='exercise[value]'][value='10.0']"
    assert_select "input[name='exercise[reps]'][value='4']"
    assert_select "input[name='exercise[added_weight]'][value='20.0']"
  end

  test "an untimed exercise keeps the hang length out of the logged value" do
    pull_ups = @user.exercise_types.create!(name: "Pull-ups", unit: "reps")

    get exercise_type_timer_path(pull_ups)

    assert_select "input#timer_work:not([name])[data-interval-timer-target=work]"
    assert_select "input[name='exercise[value]'][required]"
  end

  test "logging the set returns to the exercise type" do
    assert_difference -> { @hang.exercises.count } do
      post exercises_path, params: { exercise: { exercise_type_id: @hang.id, value: 10, reps: 5 }, return_to: exercise_type_path(@hang) }
    end

    assert_redirected_to exercise_type_path(@hang)
  end

  test "another user's exercise type is not found" do
    theirs = users(:two).exercise_types.create!(name: "Max hang", unit: "seconds")

    get exercise_type_timer_path(theirs)

    assert_response :not_found
  end
end
