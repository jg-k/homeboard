class RemoveUnitFromProblems < ActiveRecord::Migration[8.1]
  def change
    remove_column :problems, :unit, :string if column_exists?(:problems, :unit)
  end
end
