class RemoveHikedAtFromHikes < ActiveRecord::Migration[8.1]
  def change
    remove_column :hikes, :hiked_at, :datetime
  end
end
