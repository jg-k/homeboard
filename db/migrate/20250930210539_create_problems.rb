class CreateProblems < ActiveRecord::Migration[8.1]
  def change
    create_table :problems do |t|
      t.string :name
      t.string :grade
      t.string :unit
      t.references :board_layout, null: false, foreign_key: true

      t.timestamps
    end
  end
end
