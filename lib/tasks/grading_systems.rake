namespace :grading_systems do
  desc "Seed built-in grading systems (Font and V-scale). Safe to re-run."
  task seed: :environment do
    systems = {
      "Font" => %w[4 5 5+ 6a 6a+ 6b 6b+ 6c 6c+ 7a 7a+ 7b 7b+ 7c 7c+ 8a 8a+ 8b 8b+ 8c 8c+ 9a 9a+ 9b 9b+ 9c],
      "V-scale" => %w[VB V0 V1 V2 V3 V4 V5 V6 V7 V8 V9 V10 V11 V12 V13 V14 V15 V16 V17]
    }

    systems.each do |name, grades|
      gs = GradingSystem.find_or_initialize_by(name: name, system_type: "built_in")
      gs.grades = grades
      gs.save!
      puts "#{gs.previously_new_record? ? 'Created' : 'Updated'} #{name} grading system"
    end
  end
end
