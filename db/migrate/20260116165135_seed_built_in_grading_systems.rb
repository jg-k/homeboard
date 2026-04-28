class SeedBuiltInGradingSystems < ActiveRecord::Migration[8.1]
  def up
    # Font (Fontainebleau) grading system
    execute <<-SQL
      INSERT INTO grading_systems (name, grades, system_type, created_at, updated_at)
      VALUES (
        'Font',
        '["4", "5", "5+", "6a", "6a+", "6b", "6b+", "6c", "6c+", "7a", "7a+", "7b", "7b+", "7c", "7c+", "8a", "8a+", "8b", "8b+", "8c", "8c+", "9a", "9a+", "9b", "9b+", "9c"]',
        'built_in',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
    SQL

    # V-scale (Hueco) grading system
    execute <<-SQL
      INSERT INTO grading_systems (name, grades, system_type, created_at, updated_at)
      VALUES (
        'V-scale',
        '["VB", "V0", "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "V10", "V11", "V12", "V13", "V14", "V15", "V16", "V17"]',
        'built_in',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
    SQL
  end

  def down
    execute "DELETE FROM grading_systems WHERE system_type = 'built_in'"
  end
end
