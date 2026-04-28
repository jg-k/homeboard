class CreateClimbs < ActiveRecord::Migration[8.1]
  def change
    create_table :climbs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :problem, null: false, foreign_key: true
      t.string :climb_type, null: false
      t.text :notes
      t.datetime :climbed_at, null: false

      t.timestamps
    end

    add_index :climbs, [ :user_id, :climbed_at ]
    add_index :climbs, [ :problem_id, :climbed_at ]
  end
end
