class AddCircuitToProblems < ActiveRecord::Migration[8.1]
  def change
    add_column :problems, :circuit, :boolean, default: false, null: false
  end
end
