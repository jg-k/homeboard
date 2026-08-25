# WebAuthn reports whether a credential can be synced to other devices and
# whether it currently is. Nullable: a null means the authenticator told us
# nothing, which is different from it telling us "no".
class AddBackupFlagsToPasskeys < ActiveRecord::Migration[8.1]
  def change
    add_column :passkeys, :backup_eligible, :boolean
    add_column :passkeys, :backed_up, :boolean
  end
end
