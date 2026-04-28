# == Schema Information
#
# Table name: targets
#
#  id              :integer          not null, primary key
#  applicable_from :datetime         not null
#  targetable_type :string           not null
#  value           :decimal(, )      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  targetable_id   :integer          not null
#
# Indexes
#
#  index_targets_on_targetable_and_applicable_from     (targetable_type,targetable_id,applicable_from)
#  index_targets_on_targetable_type_and_targetable_id  (targetable_type,targetable_id)
#
require "test_helper"

class TargetTest < ActiveSupport::TestCase
  test "valid target" do
    target = Target.new(
      targetable: exercise_types(:running),
      value: 60,
      applicable_from: Time.current
    )
    assert target.valid?
  end

  test "requires value" do
    target = Target.new(
      targetable: exercise_types(:running),
      applicable_from: Time.current
    )
    assert_not target.valid?
    assert_includes target.errors[:value], "can't be blank"
  end

  test "requires applicable_from" do
    target = Target.new(
      targetable: exercise_types(:running),
      value: 60
    )
    assert_not target.valid?
    assert_includes target.errors[:applicable_from], "can't be blank"
  end

  test "default_scope orders by applicable_from desc" do
    exercise_type = exercise_types(:running)
    targets = exercise_type.targets
    assert_equal targets.first.value, 45 # The newer one
    assert_equal targets.last.value, 30  # The older one
  end
end
