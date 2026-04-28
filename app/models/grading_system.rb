class GradingSystem < ApplicationRecord
  belongs_to :user, optional: true
  has_many :boards, dependent: :nullify

  validates :name, presence: true
  validates :grades, presence: true
  validates :name, uniqueness: { scope: :user_id }

  scope :built_in, -> { where(system_type: "built_in") }
  scope :custom, -> { where(system_type: "custom") }
  scope :for_user, ->(user) { where(user_id: [ nil, user&.id ]).or(built_in) }

  def grades
    value = read_attribute(:grades)
    return [] if value.blank?
    value.is_a?(String) ? JSON.parse(value) : value
  rescue JSON::ParserError
    []
  end

  def grades=(value)
    write_attribute(:grades, value.is_a?(Array) ? value.to_json : value)
  end
end

# == Schema Information
#
# Table name: grading_systems
#
#  id          :integer          not null, primary key
#  grades      :text             not null
#  name        :string           not null
#  system_type :string           default("custom"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#
# Indexes
#
#  index_grading_systems_on_system_type       (system_type)
#  index_grading_systems_on_user_id           (user_id)
#  index_grading_systems_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
