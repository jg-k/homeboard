class Passkey < ApplicationRecord
  belongs_to :user

  before_validation :assign_default_nickname, on: :create

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 60 }

  scope :oldest_first, -> { order(:created_at) }

  # Everything worth keeping from a freshly verified credential.
  def self.attributes_from(credential)
    {
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: credential.sign_count,
      backup_eligible: credential.backup_eligible?,
      backed_up: credential.backed_up?
    }
  end

  # Backup state is not fixed — a credential can start life on one device and
  # later be synced — so refresh it on every sign-in rather than trusting what
  # registration recorded.
  def used!(credential)
    update!(
      sign_count: credential.sign_count,
      backed_up: credential.backed_up?,
      last_used_at: Time.current
    )
  end

  # How portable this credential is, as far as the authenticator told us.
  def storage
    return :unknown if backup_eligible.nil?
    return :device_bound unless backup_eligible?

    backed_up? ? :synced : :syncable
  end

  def device_bound?
    storage == :device_bound
  end

  def synced?
    storage == :synced
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
#  id              :integer          not null, primary key
#  backed_up       :boolean
#  backup_eligible :boolean
#  last_used_at    :datetime
#  nickname        :string           not null
#  public_key      :string           not null
#  sign_count      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  external_id     :string           not null
#  user_id         :integer          not null
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
