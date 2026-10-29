# An exercise type's sets as a share of body weight: body weight plus any
# added weight, over body weight, so a +20 kg hang at 80 kg reads 125%. Each
# set uses the last weigh-in on or before it, or the first one after for sets
# logged before any weigh-in. Sets are split by duration and reps, since only
# like protocols compare.
#
# Has the #name, #chart_data and #targets that Charts::Progress plots.
class ExerciseType::BodyweightRatio
  def initialize(exercise_type, body_weight_metric)
    @exercise_type = exercise_type
    @body_weight_metric = body_weight_metric
  end

  def name = "% body weight"

  def targets = Target.none

  def chart_data
    return [] if weigh_ins.empty?

    sets.group_by { |_, value, reps, _| protocol(value, reps) }.map do |label, rows|
      { name: label, data: rows.map { |performed_at, _, _, added| [ performed_at.to_date.iso8601, percent(performed_at, added) ] } }
    end
  end

  private

  def sets
    @exercise_type.exercises.joins(:activity_log)
                  .order("activity_logs.performed_at")
                  .pluck("activity_logs.performed_at", :value, :reps, :added_weight)
  end

  def weigh_ins
    @weigh_ins ||= @body_weight_metric.measurements.order(:recorded_at).pluck(:recorded_at, :value)
  end

  def body_weight_at(time)
    (weigh_ins.reverse.find { |recorded_at, _| recorded_at <= time } || weigh_ins.first).last
  end

  def percent(performed_at, added)
    body_weight = body_weight_at(performed_at)
    ((body_weight + added.to_d) / body_weight * 100).round(1).to_f
  end

  def protocol(value, reps)
    label = "#{value.to_s.delete_suffix('.0')} #{@exercise_type.unit}"
    reps ||= @exercise_type.reps
    reps ? "#{label} × #{reps} reps" : label
  end
end
