class AddMetaToSpreeTables < ActiveRecord::Migration
  def up
    add_column :spree_products, :meta, :jsonb, default: '{}' unless column_exists?(:spree_products, :meta)
    add_column :spree_variants, :meta, :jsonb, default: '{}' unless column_exists?(:spree_variants, :meta)
    add_column :spree_orders, :meta, :jsonb, default: '{}' unless column_exists?(:spree_orders, :meta)
    add_column :spree_promotions, :meta, :jsonb, default: '{}' unless column_exists?(:spree_promotions, :meta)
    add_column :spree_credit_cards, :meta, :jsonb, default: '{}' unless column_exists?(:spree_credit_cards, :meta)
    add_column :spree_payment_capture_events, :meta, :jsonb, default: '{}' unless column_exists?(:spree_payment_capture_events, :meta)
  end

  def down
    remove_column :spree_payment_capture_events, :meta if column_exists?(:spree_payment_capture_events, :meta)
    remove_column :spree_credit_cards, :meta if column_exists?(:spree_credit_cards, :meta)
    remove_column :spree_promotions, :meta if column_exists?(:spree_promotions, :meta)
    remove_column :spree_orders, :meta if column_exists?(:spree_orders, :meta)
    remove_column :spree_variants, :meta if column_exists?(:spree_variants, :meta)
    remove_column :spree_products, :meta if column_exists?(:spree_products, :meta)
  end
end
