# theCrag's node id for the route itself, which the ascent id cannot stand in
# for: counting goes on a route means grouping the ascents that share one.
class AddThecragRouteIdToCragAscents < ActiveRecord::Migration[8.1]
  def change
    add_column :crag_ascents, :thecrag_route_id, :string
    add_index :crag_ascents, :thecrag_route_id, where: "thecrag_route_id IS NOT NULL"
  end
end
