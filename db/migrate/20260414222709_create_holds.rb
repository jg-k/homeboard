class CreateHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :holds do |t|
      t.references :problem, null: false, foreign_key: true
      t.string :kind, null: false
      t.float :x, null: false
      t.float :y, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :holds, [ :problem_id, :kind, :position ]
  end
end
