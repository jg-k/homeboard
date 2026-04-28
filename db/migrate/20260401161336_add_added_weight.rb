class AddAddedWeight < ActiveRecord::Migration[8.1]
  def change
    add_column :exercise_types, :added_weight_possible, :boolean, default: false, null: false
    add_column :exercises, :added_weight, :decimal
  end
end
