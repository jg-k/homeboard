class CreateCragAscents < ActiveRecord::Migration[8.1]
  def change
    create_table :crag_ascents do |t|
      t.string :route_name, null: false
      t.string :ascent_type
      t.string :gear_style
      t.string :grade
      t.integer :route_height
      t.string :crag_name
      t.string :crag_path
      t.string :country
      t.string :partners
      t.text :comment
      t.integer :quality
      t.datetime :ascent_date, null: false
      t.string :thecrag_ascent_id

      t.timestamps
    end

    add_index :crag_ascents, :thecrag_ascent_id, unique: true,
              where: "thecrag_ascent_id IS NOT NULL"
  end
end
