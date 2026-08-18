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
require "test_helper"

class PasskeyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "names unnamed passkeys sequentially" do
    assert_equal "Passkey 1", build.tap(&:save!).nickname
    assert_equal "Passkey 2", build.tap(&:save!).nickname
  end

  test "skips a default name the user already took" do
    build(nickname: "Passkey 1").save!
    assert_equal "Passkey 2", build.tap(&:save!).nickname
  end

  test "keeps an explicit nickname" do
    assert_equal "Pixel", build(nickname: "Pixel").tap(&:save!).nickname
  end

  test "requires a nickname unique to the user" do
    build(nickname: "Pixel").save!
    duplicate = build(nickname: "Pixel")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:nickname], "has already been taken"
  end

  test "allows the same nickname on a different account" do
    build(nickname: "Pixel").save!
    assert users(:two).passkeys.build(attributes.merge(nickname: "Pixel")).valid?
  end

  test "requires a globally unique external id" do
    external_id = SecureRandom.uuid
    build(external_id: external_id).save!

    assert_not users(:two).passkeys.build(attributes.merge(external_id: external_id)).valid?
  end

  test "records use" do
    passkey = build.tap(&:save!)

    freeze_time do
      passkey.used!(42)
      assert_equal 42, passkey.sign_count
      assert_equal Time.current, passkey.last_used_at
    end
  end

  test "is removed with its user" do
    build.save!
    assert_difference "Passkey.count", -1 do
      @user.destroy
    end
  end

  private

  def build(**overrides)
    @user.passkeys.build(attributes.merge(overrides))
  end

  def attributes
    { external_id: SecureRandom.uuid, public_key: SecureRandom.uuid }
  end
end
