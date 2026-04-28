class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :entra_id ]

  enum :role, { user: "user", admin: "admin" }, default: :user

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
  end

  has_many :user_boards, dependent: :destroy
  has_many :boards, through: :user_boards
  has_many :grading_systems, dependent: :destroy
  has_many :exercise_types, dependent: :destroy
  has_many :metrics, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :created_problems, class_name: "Problem", foreign_key: :created_by_id, dependent: :nullify
  belongs_to :default_grading_system, class_name: "GradingSystem", optional: true

  # Follow relationships
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  def following?(user)
    following.include?(user)
  end

  def follow(user)
    active_follows.create(followed: user) unless self == user
  end

  def unfollow(user)
    active_follows.find_by(followed: user)&.destroy
  end

  def destroy
    sole_boards = boards.select { |b| b.users.count == 1 }
    super.tap do
      sole_boards.each(&:destroy)
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  allow_follows             :boolean          default(FALSE), not null
#  boardsesh_email           :string
#  boardsesh_last_synced_at  :datetime
#  boardsesh_session_token   :string
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string
#  email                     :string           default(""), not null
#  encrypted_password        :string           default(""), not null
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string
#  provider                  :string
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string
#  role                      :string           default("user"), not null
#  sign_in_count             :integer          default(0), not null
#  thecrag_synced_at         :datetime
#  thecrag_username          :string
#  uid                       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  boardsesh_user_id         :string
#  default_grading_system_id :integer
#
# Indexes
#
#  index_users_on_default_grading_system_id  (default_grading_system_id)
#  index_users_on_email                      (email) UNIQUE
#  index_users_on_provider_and_uid           (provider,uid) UNIQUE
#  index_users_on_reset_password_token       (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  default_grading_system_id  (default_grading_system_id => grading_systems.id)
#
