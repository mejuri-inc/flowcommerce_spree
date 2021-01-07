# frozen_string_literal: true

# module Spree
#   Taxon.class_eval do
#     def products_by_zone(product_zone)
#       flow_experience_key = product_zone.flow_data&.[]('key')
#       sku_regex = product_zone.sku_regex
#
#       if flow_experience_key.present?
#         products_by_experience(product_zone, sku_regex)
#       else
#         products.joins(:master).where('spree_variants.sku ~ ?', sku_regex)
#       end
#     end
#
#     def products_by_experience(flow_experience_key, sku_regex)
#       # To make the following query return a distinct array of products, raw SQL had to be used:
#       # object.products.joins(:variants).where(
#       #   "spree_variants.meta -> 'flow_data' -> 'exp' ->> '#{flow_experience_key}' IS NOT NULL"
#       # )
#       query = <<~SQL
#           SELECT DISTINCT spree_products.* FROM spree_products
#             INNER JOIN spree_variants ON spree_variants.product_id = spree_products.id AND
#               spree_variants.is_master = 'f' AND spree_variants.deleted_at IS NULL AND
#               (spree_variants.sku ~ '#{sku_regex}')
#             INNER JOIN (
#               SELECT spree_products_taxons.*, spree_products_taxons.position as position from spree_products_taxons
#                 ORDER BY position ASC
#             ) I2 ON spree_products.id = I2.product_id
#               WHERE spree_products.deleted_at IS NULL AND I2.taxon_id = #{id} AND
#                 (spree_variants.meta -> 'flow_data' -> 'exp' ->> '#{flow_experience_key}' IS NOT NULL)
#       SQL
#
#       Spree::Product.find_by_sql(query)
#     end
#   end
# end
