class Target < ApplicationRecord
  belongs_to :targetable, polymorphic: true

  validates :value, presence: true
  validates :applicable_from, presence: true

  default_scope { order(applicable_from: :desc) }
end

# == Schema Information
#
# Table name: targets
#
#  id              :integer          not null, primary key
#  applicable_from :datetime         not null
#  targetable_type :string           not null
#  value           :decimal(, )      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  targetable_id   :integer          not null
#
# Indexes
#
#  index_targets_on_targetable_and_applicable_from     (targetable_type,targetable_id,applicable_from)
#  index_targets_on_targetable_type_and_targetable_id  (targetable_type,targetable_id)
#
