class AddBodyWeightToMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :metrics, :body_weight, :boolean, default: false, null: false
  end
end
