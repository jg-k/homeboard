class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # No :validatable — it hard-requires an email, and passkey-only accounts
  # never have one. Its validations are reproduced below, email-optional.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :entra_id ]

  enum :role, { user: "user", admin: "admin" }, default: :user

  # A long-lived credential the climber hands us for their own theCrag logbook,
  # so it does not belong in the clear in a backup or a database dump. The
  # session cookie next to it stays plaintext: it predates this and there are
  # rows already holding one.
  encrypts :thecrag_api_key

  DISPLAY_NAME_FORMAT = /\A[a-z0-9][a-z0-9_-]*\z/

  before_validation :normalize_display_name

  validates :display_name, presence: true, length: { in: 3..30 },
    format: { with: DISPLAY_NAME_FORMAT, message: "can only contain lowercase letters, numbers, dashes and underscores" },
    uniqueness: { case_sensitive: false }
  validates :email, format: { with: Devise.email_regexp },
    uniqueness: { case_sensitive: false }, allow_blank: true
  validates :password, presence: true, confirmation: true,
    length: { in: Devise.password_length }, if: :password_required?

  # A handle nobody has taken yet, derived from whatever we know about the
  # user. Used when a provider signs someone up and picks no name for them.
  def self.available_display_name(candidate)
    base = candidate.to_s.downcase.gsub(/[^a-z0-9_-]/, "-").sub(/\A[^a-z0-9]+/, "")
    base = "climber" if base.length < 3
    base = base[0, 30]

    name = base
    suffix = 1
    while exists?(display_name: name)
      suffix += 1
      name = "#{base[0, 27]}#{suffix}"
    end
    name
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.display_name = available_display_name(auth.info.email.to_s.split("@").first)
      user.password = Devise.friendly_token[0, 20]
    end
  end

  OAUTH_PROVIDER_NAMES = { "google_oauth2" => "Google", "entra_id" => "Microsoft" }.freeze

  def oauth_provider_name
    OAUTH_PROVIDER_NAMES.fetch(provider, provider&.titleize)
  end

  # Attach an OAuth identity to this account, so a climber who signed up with
  # a passkey can also sign in with Google or Microsoft. One identity per
  # account: the provider/uid pair lives on the user row itself. If the
  # identity already spawned its own account -- someone hit "Sign in with
  # Google" before learning about this button -- that duplicate is folded in
  # rather than refused: the callback just proved both are the same person.
  def link_omniauth(auth)
    if provider.present?
      return true if provider == auth.provider && uid == auth.uid

      errors.add(:base, "This account is already linked to #{oauth_provider_name}.")
      return false
    end

    transaction do
      if (duplicate = User.find_by(provider: auth.provider, uid: auth.uid))
        absorb(duplicate)
      end

      self.provider = auth.provider
      self.uid = auth.uid
      # A passkey-only account has no email; the provider just vouched for one.
      oauth_email = auth.info.email.to_s.downcase
      if email.blank? && oauth_email.present? && !User.where("LOWER(email) = ?", oauth_email).exists?
        self.email = oauth_email
      end
      save!
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Fold another account into this one: everything it owns moves across and
  # the duplicate row dies. Only called once the OAuth callback has proved the
  # same person is behind both.
  def absorb(other)
    raise ArgumentError, "an account cannot absorb itself" if other == self

    transaction do
      move_renaming(other.grading_systems, :name)
      move_renaming(other.exercise_types, :name)
      move_renaming(other.metrics, :name)
      move_renaming(other.passkeys, :nickname)

      # A board or follow held by both sides would collide outright, so the
      # duplicate's copy dies with it.
      other.user_boards.where(board_id: user_boards.select(:board_id)).destroy_all
      other.active_follows.where(followed_id: [ id ] + following.ids).destroy_all
      other.passive_follows.where(follower_id: [ id ] + followers.ids).destroy_all

      other.user_boards.update_all(user_id: id)
      other.activity_logs.update_all(user_id: id)
      other.created_problems.update_all(created_by_id: id)
      other.active_follows.update_all(follower_id: id)
      other.passive_follows.update_all(followed_id: id)

      other.reload.destroy!
    end
  end

  has_many :passkeys, dependent: :destroy
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

  # The WebAuthn user handle: a stable opaque id authenticators store next to
  # each credential. Deliberately not the database id, which would otherwise be
  # copied onto every device the user registers. Generated on first use so
  # existing accounts need no backfill.
  def webauthn_handle
    update!(webauthn_id: WebAuthn.generate_user_id) if webauthn_id.blank?
    webauthn_id
  end

  private

  # Same-named records on both sides would trip a per-user unique index, so
  # the copy coming across yields the name instead.
  def move_renaming(records, attribute)
    records.to_a.each do |record|
      name = record[attribute]
      suffix = 1
      while records.klass.exists?(user_id: id, attribute => name)
        suffix += 1
        name = "#{record[attribute]} (#{suffix})"
      end
      record.update_columns(user_id: id, attribute => name)
    end
  end

  def normalize_display_name
    self.display_name = display_name&.strip&.downcase
  end

  # Devise::Models::Validatable's rule: new records always set one, and an
  # existing record only revalidates when a password is actually being changed.
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  public

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
#  display_name              :string           not null
#  email                     :string
#  encrypted_password        :string           default(""), not null
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string
#  provider                  :string
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string
#  role                      :string           default("user"), not null
#  sign_in_count             :integer          default(0), not null
#  thecrag_api_key           :string
#  thecrag_session_cookie    :string
#  thecrag_since_epoch       :integer
#  thecrag_sync_error        :string
#  thecrag_synced_at         :datetime
#  thecrag_username          :string
#  uid                       :string
#  ukc_synced_at             :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  boardsesh_user_id         :string
#  default_grading_system_id :integer
#  ukc_user_id               :string
#  webauthn_id               :string
#
# Indexes
#
#  index_users_on_default_grading_system_id  (default_grading_system_id)
#  index_users_on_display_name               (display_name) UNIQUE
#  index_users_on_email                      (email) UNIQUE
#  index_users_on_provider_and_uid           (provider,uid) UNIQUE
#  index_users_on_reset_password_token       (reset_password_token) UNIQUE
#  index_users_on_webauthn_id                (webauthn_id) UNIQUE
#
# Foreign Keys
#
#  default_grading_system_id  (default_grading_system_id => grading_systems.id)
#
