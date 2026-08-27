module ProblemsHelper
  # The filter page holds the full picture; next to the filter button only the
  # grade range is worth the space: "5a → 6b", or one-sided as "5a →" / "→ 6b".
  def grade_range_label(min_grade, max_grade)
    return if min_grade.blank? && max_grade.blank?

    "#{min_grade} → #{max_grade}".strip
  end
end
