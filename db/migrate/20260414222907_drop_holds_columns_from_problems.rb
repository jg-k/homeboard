class DropHoldsColumnsFromProblems < ActiveRecord::Migration[8.1]
  def change
    remove_column :problems, :start_holds, :text
    remove_column :problems, :finish_holds, :text
    remove_column :problems, :hand_holds, :text
    remove_column :problems, :foot_holds, :text
  end
end
