# == Schema Information
#
# Table name: crag_ascents
#
#  id                :integer          not null, primary key
#  ascent_date       :datetime         not null
#  ascent_type       :string
#  comment           :text
#  country           :string
#  crag_name         :string
#  crag_path         :string
#  gear_style        :string
#  grade             :string
#  partners          :string
#  quality           :integer
#  route_height      :integer
#  route_name        :string           not null
#  source            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  thecrag_ascent_id :string
#
# Indexes
#
#  index_crag_ascents_on_thecrag_ascent_id  (thecrag_ascent_id) UNIQUE WHERE thecrag_ascent_id IS NOT NULL
#
require "test_helper"

class CragAscentTest < ActiveSupport::TestCase
  test "validates route_name presence" do
    ascent = CragAscent.new(ascent_date: Time.current)
    assert_not ascent.valid?
    assert_includes ascent.errors[:route_name], "can't be blank"
  end

  test "validates ascent_date presence" do
    ascent = CragAscent.new(route_name: "Test Route")
    assert_not ascent.valid?
    assert_includes ascent.errors[:ascent_date], "can't be blank"
  end

  test "validates thecrag_ascent_id uniqueness" do
    CragAscent.create!(route_name: "Route A", ascent_date: Time.current, thecrag_ascent_id: "unique123")
    duplicate = CragAscent.new(route_name: "Route B", ascent_date: Time.current, thecrag_ascent_id: "unique123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:thecrag_ascent_id], "has already been taken"
  end

  test "allows nil thecrag_ascent_id" do
    ascent = CragAscent.new(route_name: "Route A", ascent_date: Time.current, thecrag_ascent_id: nil)
    assert ascent.valid?
  end

  test "ascent_type enum values" do
    ascent = CragAscent.new(route_name: "Route", ascent_date: Time.current)

    %w[onsight flash redpoint send tick attempt hang_dog clean pink_point].each do |type|
      ascent.ascent_type = type
      assert_equal type, ascent.ascent_type
    end
  end

  test "gear_style enum values" do
    ascent = CragAscent.new(route_name: "Route", ascent_date: Time.current)

    %w[sport trad boulder].each do |style|
      ascent.gear_style = style
      assert_equal style, ascent.gear_style
    end
  end

  test "has activity_log association" do
    ascent = CragAscent.create!(route_name: "Route", ascent_date: Time.current)
    activity_log = ascent.create_activity_log!(user: users(:one), performed_at: ascent.ascent_date)

    assert_equal activity_log, ascent.activity_log
    assert_equal ascent, activity_log.loggable
  end

  test "destroying ascent destroys activity_log" do
    ascent = CragAscent.create!(route_name: "Route", ascent_date: Time.current)
    ascent.create_activity_log!(user: users(:one), performed_at: ascent.ascent_date)

    assert_difference "ActivityLog.count", -1 do
      ascent.destroy
    end
  end
end
