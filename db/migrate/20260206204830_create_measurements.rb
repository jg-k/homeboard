class CreateMeasurements < ActiveRecord::Migration[8.1]
  def change
    create_table :measurements do |t|
      t.decimal :value, null: false
      t.datetime :recorded_at, null: false
      t.text :notes
      t.references :metric, null: false, foreign_key: true

      t.timestamps
    end

    add_index :measurements, [ :metric_id, :recorded_at ]
  end
end
