require "application_system_test_case"

class IntervalTimerTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  test "counts down the hangs and rests, then logs the set" do
    user = users(:one)
    hang = user.exercise_types.create!(name: "Max hang", unit: "seconds", added_weight_possible: true)
    sign_in user

    visit exercise_type_timer_path(hang)
    fill_in "Hang (s)", with: 1
    fill_in "Rest (s)", with: 1
    fill_in "Reps", with: 2
    fill_in "Added weight (kg)", with: 20
    click_on "Start"

    assert_selector ".timer-display[data-phase=ready]"
    assert_selector ".timer-display[data-phase=hang]", text: "Rep 1 of 2", wait: 7
    assert_selector ".timer-display[data-phase=rest]", wait: 2
    assert_selector ".timer-display[data-phase=hang]", text: "Rep 2 of 2", wait: 2
    assert_selector ".timer-display[data-phase=done]", wait: 2
    assert_button "Again"

    click_on "Log set"

    assert_current_path exercise_type_path(hang)
    exercise = hang.exercises.sole
    assert_equal [ 1, 2, 20 ], [ exercise.value, exercise.reps, exercise.added_weight ]
  end
end
