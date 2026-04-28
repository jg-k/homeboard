class AddAllowFollowsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :allow_follows, :boolean, default: false, null: false
  end
end
