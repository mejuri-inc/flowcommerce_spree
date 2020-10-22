class AddOptionsToSpreeTables < ActiveRecord::Migration
  def up
    add_column :spree_products, :options, :jsonb, default: '{}' unless column_exists?(:spree_products, :options)
    add_column :spree_variants, :options, :jsonb, default: '{}' unless column_exists?(:spree_variants, :options)
    add_column :spree_orders, :options, :jsonb, default: '{}' unless column_exists?(:spree_orders, :options)
    add_column :spree_promotions, :options, :jsonb, default: '{}' unless column_exists?(:spree_promotions, :options)
    add_column :spree_credit_cards, :options, :jsonb, default: '{}' unless column_exists?(:spree_credit_cards, :options)
  end

  def down
    remove_column :spree_products, :options if column_exists?(:spree_products, :options)
    remove_column :spree_variants, :options if column_exists?(:spree_variants, :options)
    remove_column :spree_orders, :options if column_exists?(:spree_orders, :options)
    remove_column :spree_promotions, :options if column_exists?(:spree_promotions, :options)
    remove_column :spree_credit_cards, :options if column_exists?(:spree_credit_cards, :options)
  end
end
