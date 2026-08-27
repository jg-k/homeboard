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
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a display name" do
    assert_not build(display_name: nil).valid?
    assert_not build(display_name: "  ").valid?
  end

  test "normalizes the display name" do
    user = build(display_name: "  MixedCase  ")
    user.validate

    assert_equal "mixedcase", user.display_name
  end

  test "rejects display names that would not work as a handle" do
    [ "no spaces", "has.dot", "-leading", "a", "ab", "x" * 31 ].each do |name|
      assert_not build(display_name: name).valid?, "expected #{name.inspect} to be rejected"
    end
  end

  test "accepts handle-shaped display names" do
    [ "climber", "climber-2", "climber_2", "9lives" ].each do |name|
      assert build(display_name: name).valid?, "expected #{name.inspect} to be accepted"
    end
  end

  test "requires the display name to be unique regardless of case" do
    assert_not build(display_name: users(:one).display_name.upcase).valid?
  end

  test "allows an account with no email at all" do
    user = build(email: nil)

    assert user.valid?
    assert user.save
  end

  test "still validates an email when one is given" do
    assert_not build(email: "nonsense").valid?
    assert_not build(email: users(:one).email).valid?
  end

  test "available_display_name derives a free handle" do
    assert_equal "brandnew", User.available_display_name("BrandNew")
    assert_equal "climber", User.available_display_name("!")
    assert_equal "climber", User.available_display_name("ab")
    assert_equal "#{users(:one).display_name}2", User.available_display_name(users(:one).display_name)
  end

  test "from_omniauth gives the new account a display name" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "12345",
      info: { email: "newperson@example.com" }
    )

    user = User.from_omniauth(auth)

    assert user.persisted?
    assert_equal "newperson", user.display_name
  end

  private

  def build(**overrides)
    User.new({ display_name: "someone", email: "someone@example.com", password: "password123" }.merge(overrides))
  end
end
