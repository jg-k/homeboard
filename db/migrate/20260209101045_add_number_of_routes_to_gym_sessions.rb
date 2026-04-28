class AddNumberOfRoutesToGymSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :gym_sessions, :number_of_routes, :integer
  end
end
