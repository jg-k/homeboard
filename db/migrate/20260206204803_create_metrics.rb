class CreateMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :metrics do |t|
      t.string :name, null: false
      t.string :unit, null: false
      t.string :category, null: false, default: "other"
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :metrics, [ :user_id, :name ], unique: true
  end
end
