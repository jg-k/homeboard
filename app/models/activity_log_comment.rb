class ActivityLogComment < ApplicationRecord
  CATEGORIES = %w[safety obs other].freeze

  belongs_to :activity_log

  validates :body, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :chronological, -> { order(created_at: :desc) }

  def self.category_label(category)
    category.to_s.titleize
  end

  def self.category_badge_color(category)
    case category.to_s
    when "safety" then :red
    when "obs" then :blue
    else :gray
    end
  end
end

# == Schema Information
#
# Table name: activity_log_comments
#
#  id              :integer          not null, primary key
#  body            :text             not null
#  category        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  activity_log_id :integer          not null
#
# Indexes
#
#  index_activity_log_comments_on_activity_log_id  (activity_log_id)
#  index_activity_log_comments_on_category         (category)
#
# Foreign Keys
#
#  activity_log_id  (activity_log_id => activity_logs.id)
#
