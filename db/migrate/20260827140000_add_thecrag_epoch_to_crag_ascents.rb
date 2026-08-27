# When theCrag last created or edited the ascent, so a later sync can tell an
# edit it has not seen from one it has already applied.
class AddThecragEpochToCragAscents < ActiveRecord::Migration[8.1]
  def change
    add_column :crag_ascents, :thecrag_epoch, :integer
  end
end
