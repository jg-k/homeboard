class CreateGymSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :gym_sessions do |t|
      t.integer :number_of_boulders
      t.integer :number_of_circuits
      t.integer :duration_minutes
      t.text :notes

      t.timestamps
    end
  end
end
