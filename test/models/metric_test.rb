require "test_helper"

class MetricTest < ActiveSupport::TestCase
  test "marking a metric as body weight releases the previous one" do
    user = users(:one)
    old = user.metrics.create!(name: "Weight (morning)", unit: "kg", body_weight: true)
    new = user.metrics.create!(name: "Weight", unit: "kg", body_weight: true)

    assert_not old.reload.body_weight?
    assert_equal new, user.reload.body_weight_metric
  end

  test "another user's body weight is left alone" do
    theirs = users(:two).metrics.create!(name: "Weight", unit: "kg", body_weight: true)
    users(:one).metrics.create!(name: "Weight", unit: "kg", body_weight: true)

    assert theirs.reload.body_weight?
  end
end
