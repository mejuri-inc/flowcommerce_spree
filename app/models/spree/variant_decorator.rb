# Flow specific methods for Spree::Variant
# Spree save all the prices inside Variant object. We choose to have a cache jsonb field named flow_data that will
# hold all important Flow sync data for specific experiences.
module Spree
  Variant.class_eval do
    serialize :flow_data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    # after every save we sync product we generate sh1 checksums to update only when change happend
    after_save :sync_product_to_flow

    # clears flow cache from all records
    def self.truncate_flow_data
      all_records = all.size
      update_all(flow_data: nil)
      puts "Truncated #{all_records} records"
    end

    # upload product variant to Flow's Product Catalog
    def sync_product_to_flow
      # initial Spree seed will fail, so skip unless we have Flow data field
      return if !respond_to?(:flow_data) || Flow::API_KEY.blank? || Flow::API_KEY == 'test_key'

      return { error: 'Price is 0' } if price == 0

      # master is not sellable, if product has other variants
      return { error: 'Master not sellable, if product has other variants' } if is_master? && product.variants.size > 1

      additional_attrs = {}

      if self.class.const_defined?('FLOW_ADDITIONAL_ATTRS')
        FLOW_ADDITIONAL_ATTRS_KEYS.each do |key|
          export_required = FLOW_ADDITIONAL_ATTRS[key][:export] == :required
          attr_value = __send__(key)
          return { error: "Variant with sku = #{sku} has no #{key}" } if export_required && attr_value.blank?

          additional_attrs[key] = attr_value
        end
      end

      flow_item     = flow_api_item(additional_attrs)
      flow_item_sh1 = Digest::SHA1.hexdigest(flow_item.to_json)

      # skip if sync not needed
      return nil if flow_data[:last_sync_sh1] == flow_item_sh1

      response = FlowCommerce.instance.items.put_by_number(Flow::ORGANIZATION, sku.downcase.split('p')[1], flow_item)

      # after successful put, write cache
      update_column(:flow_data, flow_data.merge('last_sync_sh1' => flow_item_sh1).to_json)

      response
    rescue Net::OpenTimeout => e
      return { error: e.message }
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
    def flow_api_item(additional_attrs)
      image_base = ENV.fetch('ASSET_HOST_PROTOCOL', 'https') + '://' + ENV.fetch('ASSET_HOST', 'staging.mejuri.com')

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
        { url: image_base + image.attachment(:large), tags: ['checkout'] },
        { url: image_base + image.attachment.url(:product), tags: ['thumbnail'] }
      ] : []

      Io::Flow::V0::Models::ItemForm.new(
        number:      sku.downcase.split('p')[1],
        locale:      'en_US',
        language:    'en',
        name:        product.name,
        description: product.description,
        currency:    cost_currency,
        price:       price.to_f,
        images:      images,
        categories: categories,
        attributes: common_attrs(taxon).merge!(additional_attrs)
      )
    end

    def common_attrs(taxon)
      {
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
    end

    # gets flow catalog item, and imports it
    # called from flow:sync_localized_items rake task
    def flow_import_item(item)
      experience_key = item.local.experience.key.to_sym
      flow_data[:exp] ||= {}
      flow_data[:exp][experience_key] = { status: item.local.status.value }
      flow_data[:exp][experience_key][:prices] = item.local.prices.map do |price|
        price = price.to_hash
        [:includes, :adjustment].each { |el| price.delete(el) unless price[el] }
        price
      end

      update_column(:flow_data, flow_data.to_json)
    end
  end
end
