class AddHoldsToProblems < ActiveRecord::Migration[8.1]
  def change
    add_column :problems, :start_holds, :text
    add_column :problems, :finish_holds, :text
  end
end
