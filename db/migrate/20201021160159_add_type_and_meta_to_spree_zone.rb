class AddTypeAndMetaToSpreeZone < ActiveRecord::Migration
  def up
    add_column :spree_zones, :klass, :text unless column_exists?(:spree_zones, :klass)
    add_column :spree_zones, :status, :text unless column_exists?(:spree_zones, :status)
    add_column :spree_zones, :meta, :jsonb, default: '{}' unless column_exists?(:spree_zones, :meta)

    add_index :spree_zones, :meta, using: :gin unless index_exists?(:spree_zones, :meta)
    add_index :spree_zones, %i[id klass] unless index_exists?(:spree_zones, %i[id klass])
    add_index :spree_zones, %i[klass name], unique: true unless index_exists?(:spree_zones, %i[klass name])
    add_index :spree_zones, :status unless index_exists?(:spree_zones, :status)
  end

  def down
    remove_index :spree_zones, :status if index_exists?(:spree_zones, :status)
    remove_index :spree_zones, %i[klass name] if index_exists?(:spree_zones, %i[klass name])
    remove_index :spree_zones, %i[id klass] if index_exists?(:spree_zones, %i[id klass])
    remove_index :spree_zones, :meta if index_exists?(:spree_zones, :meta)

    remove_column :spree_zones, :meta if column_exists?(:spree_zones, :meta)
    remove_column :spree_zones, :status if column_exists?(:spree_zones, :status)
    remove_column :spree_zones, :klass if column_exists?(:spree_zones, :klass)
  end
end
