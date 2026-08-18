class Passkey < ApplicationRecord
  belongs_to :user

  before_validation :assign_default_nickname, on: :create

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 60 }

  scope :oldest_first, -> { order(:created_at) }

  def used!(sign_count)
    update!(sign_count: sign_count, last_used_at: Time.current)
  end

  private

  def assign_default_nickname
    return if nickname.present?

    taken = user&.passkeys&.pluck(:nickname) || []
    number = 1
    number += 1 while taken.include?("Passkey #{number}")
    self.nickname = "Passkey #{number}"
  end
end

# == Schema Information
#
# Table name: passkeys
#
#  id           :integer          not null, primary key
#  last_used_at :datetime
#  nickname     :string           not null
#  public_key   :string           not null
#  sign_count   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_passkeys_on_external_id           (external_id) UNIQUE
#  index_passkeys_on_user_id               (user_id)
#  index_passkeys_on_user_id_and_nickname  (user_id,nickname) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
