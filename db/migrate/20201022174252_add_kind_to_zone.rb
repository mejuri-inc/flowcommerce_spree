# This is from Spree 3.0
# https://github.com/spree/spree/commit/f9509a511def39de9d98199ddbf35f35c8580ca4#diff-984b308f2dc59ffb6e47183ac28b9895cfaa58bb26fb6f6e56a6afbe888fdece
class AddKindToZone < ActiveRecord::Migration
  def up
    unless column_exists?(:spree_zones, :kind)
      add_column :spree_zones, :kind, :string
      add_index :spree_zones, :kind

      Spree::Zone.find_each do |zone|
        last_type = zone.members.where.not(zoneable_type: nil).pluck(:zoneable_type).last
        zone.update_column :kind, last_type.demodulize.underscore if last_type
      end
    end

    add_index :spree_zones, :kind unless index_exists?(:spree_zones, :kind)
  end

  def down
    remove_index :spree_zones, :kind if index_exists?(:spree_zones, :kind)
    remove_column :spree_zones, :kind if column_exists?(:spree_zones, :kind)
  end
end
