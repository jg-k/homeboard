class ActivityLog < ApplicationRecord
  belongs_to :user
  delegated_type :loggable, types: %w[BoardClimb Exercise GymSession CragAscent SystemBoardClimb Hike]

  validates :performed_at, presence: true

  scope :chronological, -> { order(performed_at: :desc) }
  scope :recent, -> { chronological.limit(100) }
end

# == Schema Information
#
# Table name: activity_logs
#
#  id            :integer          not null, primary key
#  loggable_type :string           not null
#  performed_at  :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  loggable_id   :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  index_activity_logs_on_loggable                   (loggable_type,loggable_id)
#  index_activity_logs_on_loggable_type_and_user_id  (loggable_type,user_id)
#  index_activity_logs_on_user_id                    (user_id)
#  index_activity_logs_on_user_id_and_performed_at   (user_id,performed_at)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
