class AddDefaultGradingSystemToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :default_grading_system, foreign_key: { to_table: :grading_systems }
  end
end
