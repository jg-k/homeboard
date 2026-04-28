class AddGradingSystemToProblems < ActiveRecord::Migration[8.1]
  def change
    add_reference :problems, :grading_system, foreign_key: true
  end
end
