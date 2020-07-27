class AddFlowData < ActiveRecord::Migration
  def up
    add_column :spree_products, :flow_data, :jsonb, default: '{}' unless column_exists?(:spree_products, :flow_data)
    add_column :spree_variants, :flow_data, :jsonb, default: '{}' unless column_exists?(:spree_variants, :flow_data)
    add_column :spree_orders, :flow_data, :jsonb, default: '{}' unless column_exists?(:spree_orders, :flow_data)
    add_column :spree_promotions, :flow_data, :jsonb, default: '{}' unless column_exists?(:spree_promotions, :flow_data)
    add_column :spree_credit_cards, :flow_data, :jsonb, default: '{}' unless column_exists?(:spree_credit_cards, :flow_data)
  end

  def down
    remove_column :spree_products, :flow_data if column_exists?(:spree_products, :flow_data)
    remove_column :spree_variants, :flow_data if column_exists?(:spree_variants, :flow_data)
    remove_column :spree_orders, :flow_data if column_exists?(:spree_orders, :flow_data)
    remove_column :spree_promotions, :flow_data if column_exists?(:spree_promotions, :flow_data)
    remove_column :spree_credit_cards, :flow_data if column_exists?(:spree_credit_cards, :flow_data)
  end
end
