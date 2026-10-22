require "test_helper"

class ClimbingGradeTest < ActiveSupport::TestCase
  def boulder(grade) = ClimbingGrade.normalize(grade, discipline: :boulder)
  def route(grade) = ClimbingGrade.normalize(grade, discipline: :sport)

  test "Font boulder grades keep their grade, whatever the prefix or case" do
    assert_equal %w[6A+ 7B 6C 5B 4C], [ "6A+", "Font 7B", "fb6c", "5B", "4c" ].map { boulder(_1) }
  end

  test "low Font grades without a letter, and 5A+, land on the lettered scale" do
    assert_equal %w[5A 5C 4A 4C 5A], [ "f5", "5+", "4", "4+", "5A+" ].map { boulder(_1) }
  end

  test "V grades become Font, taking the lower where one spans two" do
    assert_equal %w[3 4A 5A 5C 6A 6B 6C 7B 8A], %w[VB V0+ V1 V2 V3 V4 V5 V8 V11].map { boulder(_1) }
  end

  test "French sport grades keep their grade" do
    assert_equal %w[6a+ 7b 8c+ 6b], %w[6a+ 7b 8c+ F6b].map { route(_1) }
  end

  test "British trad grades go by the adjectival grade, not the technical one" do
    assert_equal %w[5c 5c 5b 4c 4b 4a 3 8c], [ "E1 5b", "E1 6a", "HVS 5a", "MVS 4c", "HS 4c", "S 4b", "VD", "E10 7a" ].map { route(_1) }
  end

  test "YDS grades become French, with a missing letter read as a and a plus as c" do
    assert_equal %w[6b+ 6a 7b+ 5c], %w[5.11a 5.10 5.12+ 5.9].map { route(_1) }
  end

  test "UIAA grades, roman or arabic, become French" do
    assert_equal %w[6a 6a+ 7a+ 8a], %w[VI+ 7- 8 IX+].map { route(_1) }
  end

  test "Ewbank grades become French" do
    assert_equal %w[6b+ 7b 8a], %w[21 25 28].map { route(_1) }
  end

  test "French low grades written without a letter" do
    assert_equal %w[4a 5c 3], %w[4 5+ 3].map { route(_1) }
  end

  test "sport and trad read grades the same way" do
    assert_equal ClimbingGrade.normalize("E1 5b", discipline: :sport), ClimbingGrade.normalize("E1 5b", discipline: :trad)
  end

  test "anything else is unreadable" do
    assert_nil route("Project")
    assert_nil boulder("Hard")
    assert_nil route("")
    assert_nil boulder(nil)
  end

  test "the logbook's gear style decides the discipline" do
    assert_equal :boulder, ClimbingGrade.discipline("6a", gear_style: "boulder")
    assert_equal :sport, ClimbingGrade.discipline("6A", gear_style: "sport")
    assert_equal :trad, ClimbingGrade.discipline("6a", gear_style: "trad")
  end

  test "without a gear style, the grade's look decides" do
    assert_equal %i[boulder boulder boulder sport sport sport trad trad],
                 [ "V5", "6A", "f5", "7a", "6a+", "5.10a", "VS", "E1 5b" ].map { ClimbingGrade.discipline(_1) }
  end

  test "every conversion lands on its scale" do
    (ClimbingGrade::V_TO_FONT.values + ClimbingGrade::BARE_FONT.values).each { assert_includes ClimbingGrade::FONT, _1 }
    [ ClimbingGrade::BRITISH_TO_FRENCH, ClimbingGrade::UIAA_TO_FRENCH, ClimbingGrade::YDS_TO_FRENCH,
      ClimbingGrade::EWBANK_TO_FRENCH, ClimbingGrade::BARE_FRENCH ].flat_map(&:values).each do
      assert_includes ClimbingGrade::FRENCH, _1
    end
  end
end
