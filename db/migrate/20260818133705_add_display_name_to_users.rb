# Identity moves off the email address: passkey-only accounts never have one,
# and the app used the email as a public handle (buddy search, activity pages).
class AddDisplayNameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :display_name, :string

    backfill_display_names
    change_column_null :users, :display_name, false
    add_index :users, :display_name, unique: true

    execute "UPDATE users SET email = NULL WHERE email = ''"
    change_column_default :users, :email, from: "", to: nil
    change_column_null :users, :email, true
  end

  def down
    remove_index :users, :display_name
    remove_column :users, :display_name

    execute "UPDATE users SET email = '' WHERE email IS NULL"
    change_column_null :users, :email, false
    change_column_default :users, :email, from: nil, to: ""
  end

  private

  def backfill_display_names
    taken = []

    select_all("SELECT id, email FROM users ORDER BY id").each do |row|
      name = unique_name(row["email"], taken)
      taken << name
      execute("UPDATE users SET display_name = #{quote(name)} WHERE id = #{row['id'].to_i}")
    end
  end

  def unique_name(email, taken)
    base = email.to_s.split("@").first.to_s.downcase.gsub(/[^a-z0-9_-]/, "-")
    base = "climber" if base.length < 3

    name = base
    suffix = 1
    while taken.include?(name)
      suffix += 1
      name = "#{base}#{suffix}"
    end
    name
  end
end
