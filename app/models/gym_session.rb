class GymSession < ApplicationRecord
  has_one :activity_log, as: :loggable, dependent: :destroy

  validate :at_least_one_field_present

  attr_accessor :performed_at

  def self.chart_data(user)
    GymSession.joins(:activity_log)
              .where(activity_logs: { user_id: user.id })
              .order("activity_logs.performed_at")
              .pluck("activity_logs.performed_at", :number_of_boulders, :number_of_circuits)
              .map { |date, boulders, circuits| [ date.to_date.iso8601, (boulders || 0) + (circuits || 0) ] }
  end

  private

  def at_least_one_field_present
    if number_of_boulders.blank? && number_of_routes.blank? && number_of_circuits.blank? && duration_minutes.blank?
      errors.add(:base, "At least one of number of boulders, number of routes, number of circuits, or duration must be provided")
    end
  end
end

# == Schema Information
#
# Table name: gym_sessions
#
#  id                 :integer          not null, primary key
#  duration_minutes   :integer
#  notes              :text
#  number_of_boulders :integer
#  number_of_circuits :integer
#  number_of_routes   :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
