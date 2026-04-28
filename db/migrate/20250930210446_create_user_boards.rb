class CreateUserBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :user_boards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :board, null: false, foreign_key: true

      t.timestamps
    end
  end
end
