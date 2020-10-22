class AddZoneTypeToSpreeZoneMembers < ActiveRecord::Migration
  def up
    add_column :spree_zone_members, :zone_type, :text unless column_exists?(:spree_zone_members, :zone_type)

    unless index_exists?(:spree_zone_members, %i[zone_id zone_type])
      add_index :spree_zone_members, %i[zone_id zone_type],
                name: "index_spree_zone_members_on_zone_id_and_zone_type", using: :btree
    end

    if index_exists?(:spree_zone_members, name: "index_spree_zone_members_on_zone_id")
      remove_index :spree_zone_members, name: "index_spree_zone_members_on_zone_id"
    end
  end

  def down
    add_index :spree_zone_members, :zone_id unless index_exists?(:spree_zone_members, :zone_id)

    if index_exists?(:spree_zone_members, %i[zone_id zone_type])
      remove_index :spree_zone_members, name: "index_spree_zone_members_on_zone_id_and_zone_type"
    end

    remove_column :spree_zone_members, :zone_type if column_exists?(:spree_zone_members, :zone_type)
  end
end
