namespace :exercises do
  # Parses reps and added_weight out of legacy ExerciseType names where the
  # prescription was baked into the type name (e.g. "Deadlift 52kg, x5").
  # Idempotent — only fills fields that are currently nil.
  desc "Backfill reps + added_weight on ExerciseType rows from their name"
  task backfill_metrics: :environment do
    rules = [
      [ /\bDeadlift\s+(\d+)\s*kg.*?x\s*(\d+)/i, ->(m) { { added_weight_possible: true, reps: m[2].to_i } } ],
      [ /\bPull\s*up,?\s*(\d+)\s*reps?.*?(\d+)\s*s\s*rest/i, ->(m) { { reps: m[1].to_i, rest_seconds: m[2].to_i } } ],
      [ /\bPull\s*ups?,?\s*(\d+)\s*reps?.*?(\d+)\s*s\s*rest/i, ->(m) { { reps: m[1].to_i, rest_seconds: m[2].to_i } } ],
      [ /\bPull\s*ups?,?\s*(\d+)\s*reps?/i, ->(m) { { reps: m[1].to_i } } ],
      [ /\bPush\s*ups?.*?x\s*(\d+)/i, ->(m) { { reps: m[1].to_i } } ],
      [ /\bWipers.*?(\d+)\s*reps?/i, ->(m) { { reps: m[1].to_i } } ],
      [ /\bL\s*sit.*?(\d+)\s*s.*?(\d+)\s*s\s*rest/i, ->(m) { { rest_seconds: m[2].to_i } } ]
    ].freeze

    total_updated = 0
    total_skipped = 0

    ExerciseType.find_each do |type|
      regex, builder = rules.find { |r, _| r.match(type.name) }
      next unless regex
      attrs = builder.call(regex.match(type.name))

      fillable = attrs.reject { |k, _| type[k].present? }
      if fillable.empty?
        total_skipped += 1
        next
      end

      type.update_columns(fillable.merge(updated_at: Time.current))
      total_updated += 1
      puts "  #{type.name.ljust(35)} type##{type.id}  ← #{fillable.inspect}"
    end

    puts "-" * 60
    puts "Updated: #{total_updated}, already-set (skipped): #{total_skipped}"
  end

  # Renames legacy ExerciseTypes whose names baked in the prescription, and
  # merges duplicates that are the same movement at a different prescription.
  # Run AFTER backfill_metrics so reps/rest_seconds are preserved on the type.
  desc "Strip prescriptions from ExerciseType names + merge equivalents"
  task cleanup_names: :environment do
    renames = {
      "Deadlift 52kg, x5"             => "Deadlift",
      "Push ups, classics, x10"       => "Push ups, classics",
      "Wipers - homeboard - 10 reps"  => "Wipers - homeboard",
      "Pull up, 5 rep, 45s rest"      => "Pull up",
      "Pull ups, 3reps, 45s rest"     => "Pull up",
      "L sit 10s, 30s rest"           => "L sit, 10s hold",
      "L sit bent legs 30s, 30s rest" => "L sit bent legs, 30s hold"
    }.freeze

    ActiveRecord::Base.transaction do
      renames.each do |old_name, new_name|
        source = ExerciseType.find_by(name: old_name)
        next unless source

        target = ExerciseType.where(user_id: source.user_id, name: new_name)
                             .where.not(id: source.id).first

        if target
          puts "  MERGE  '#{old_name}' (#{source.exercises.count} logs) → '#{new_name}' (##{target.id})"
          source.exercises.update_all(exercise_type_id: target.id)
          source.destroy!
        else
          puts "  RENAME '#{old_name}' → '#{new_name}'"
          source.update!(name: new_name)
        end
      end
    end
  end
end
