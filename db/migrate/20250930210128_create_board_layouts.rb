class CreateBoardLayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :board_layouts do |t|
      t.string :name
      t.references :board, null: false, foreign_key: true

      t.timestamps
    end
  end
end
