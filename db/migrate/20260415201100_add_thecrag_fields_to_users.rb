class AddThecragFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :thecrag_username, :string
    add_column :users, :thecrag_synced_at, :datetime
  end
end
