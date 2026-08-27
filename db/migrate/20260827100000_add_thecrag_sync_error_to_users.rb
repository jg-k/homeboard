# Why a sync stopped for a reason the climber has to act on: a revoked key, a
# spent token budget, a logbook too large to read in one pass.
class AddThecragSyncErrorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :thecrag_sync_error, :string
  end
end
