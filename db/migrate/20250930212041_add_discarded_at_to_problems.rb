class AddDiscardedAtToProblems < ActiveRecord::Migration[8.1]
  def change
    add_column :problems, :discarded_at, :datetime
    add_index :problems, :discarded_at
  end
end
