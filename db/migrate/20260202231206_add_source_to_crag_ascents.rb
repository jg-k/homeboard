class AddSourceToCragAscents < ActiveRecord::Migration[8.1]
  def change
    add_column :crag_ascents, :source, :string
  end
end
