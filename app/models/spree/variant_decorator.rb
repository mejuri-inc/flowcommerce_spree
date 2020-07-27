# Flow specific methods for Spree::Variant
# Spree save all the prices inside Variant object
# we choose to have cache jsonb field named flow_data that will hold all important
# flow sync data for specific
module Spree
  Variant.class_eval do
    # after every save we sync product
    # we generate sh1 checksums to update only when change happend
    after_save :flow_sync_product

    # clears flow cache from all records
    def self.flow_truncate
      all_records = all
      all_records.each { |o| o.update_column :flow_data, {} }
      puts 'Truncated %d records' % all_records.length
    end

    # syncs product variant with flow
    def flow_sync_product
      # initial Spree seed will fail, so skip unless we have Flow data folder
      return unless respond_to?(:flow_data)

      flow_item     = flow_api_item
      flow_item_sh1 = Digest::SHA1.hexdigest flow_api_item.to_json

      # skip if sync not needed
      return nil if flow_data['last_sync_sh1'] == flow_item_sh1

      response = FlowCommerce.instance.items.put_by_number(Flow::ORGANIZATION, id.to_s, flow_item)

      # after successful put, write cache
      update_column(:flow_data, flow_data.merge('last_sync_sh1' => flow_item_sh1).to_json)

      response
    end

    def flow_spree_price
      '%s %s' % [self.price, self.cost_currency]
    end

    def flow_prices(flow_exp)
      flow_data.dig('exp', flow_exp.key, 'prices') || []
    end

    # returns price tied to local experience
    def flow_local_price(flow_exp)
      price = flow_prices(flow_exp).first

      if flow_exp && price
        price['label']
      else
        flow_spree_price
      end
    end

    # creates object for flow api
    # TODO: Remove and use the one in rakefile
    def flow_api_item
      image_base = ENV.fetch('ASSET_HOST')

      # add product categories
      categories = []
      taxon = product.taxons.first
      current_taxon = taxon
      while current_taxon
        categories.unshift current_taxon.name
        current_taxon = current_taxon.parent
      end

      image = product.images.first || product.variant_images.first
      images = image ? [
        { url: image_base + image.attachment(:large), tags: ['main'] },
        { url: image_base + image.attachment.url(:product), tags: ['thumbnail'] }
      ] : []

      Io::Flow::V0::Models::ItemForm.new(
        number:      id.to_s,
        locale:      'en_US',
        language:    'en',
        name:        product.name,
        description: product.description,
        currency:    cost_currency,
        price:       price.to_f,
        images:      images,
        categories: categories,
        attributes: {
                       weight: weight.to_s,
                       height: height.to_s,
                       width: width.to_s,
                       depth: depth.to_s,
                       is_master: is_master ? 'true' : 'false',
                       product_id: product_id.to_s,
                       tax_category: product.tax_category_id.to_s,
                       product_description: product.description,
                       product_shipping_category: product.shipping_category_id ? shipping_category.name : nil,
                       product_meta_title: taxon&.meta_title.to_s,
                       product_meta_description: taxon&.meta_description.to_s,
                       product_meta_keywords: taxon&.meta_keywords.to_s,
                       product_slug: product.slug,
                     }.select{ |k,v| v.present? }
      )
    end

    # gets flow catalog item, and imports it
    # called from flow:sync_localized_items rake task
    def flow_import_item(item)
      experience_key = item.local.experience.key
      flow_data['exp'] ||= {}
      flow_data['exp'][experience_key] = {}
      flow_data['exp'][experience_key]['status'] = item.local.status.value
      flow_data['exp'][experience_key]['prices'] = item.local.prices.map do |price|
        price = price.to_hash
        [:includes, :adjustment].each { |el| price.delete(el) unless price[el] }
        price
      end

      update_column :flow_data, flow_data.dup
    end
  end
end
