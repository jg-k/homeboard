class AddCreatedByToProblems < ActiveRecord::Migration[8.1]
  def change
    add_reference :problems, :created_by, foreign_key: { to_table: :users }
  end
end
