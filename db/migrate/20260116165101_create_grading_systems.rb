class CreateGradingSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :grading_systems do |t|
      t.string :name, null: false
      t.text :grades, null: false
      t.string :system_type, null: false, default: "custom"
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :grading_systems, :system_type
    add_index :grading_systems, [ :user_id, :name ], unique: true
  end
end
