class AddHandAndFootHoldsToProblems < ActiveRecord::Migration[8.1]
  def change
    add_column :problems, :hand_holds, :text
    add_column :problems, :foot_holds, :text
  end
end
