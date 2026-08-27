# theCrag issues supporters a personal key granting read access to their own
# logbook. It beats scraping: no session to borrow, no page budget to spend, and
# `since` makes repeat syncs cheap -- so remember how far we got.
class AddThecragApiKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :thecrag_api_key, :string
    add_column :users, :thecrag_since_epoch, :integer
  end
end
