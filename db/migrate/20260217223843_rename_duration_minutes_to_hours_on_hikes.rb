class RenameDurationMinutesToHoursOnHikes < ActiveRecord::Migration[8.1]
  def change
    remove_column :hikes, :duration_minutes, :integer
    add_column :hikes, :duration_hours, :decimal, precision: 4, scale: 2
  end
end
