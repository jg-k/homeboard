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
