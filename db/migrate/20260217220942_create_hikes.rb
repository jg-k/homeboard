class CreateHikes < ActiveRecord::Migration[8.1]
  def change
    create_table :hikes do |t|
      t.string :name, null: false
      t.decimal :distance_km, precision: 6, scale: 2
      t.integer :elevation_gain_m
      t.integer :duration_minutes
      t.text :notes
      t.datetime :hiked_at, null: false

      t.timestamps
    end
  end
end
