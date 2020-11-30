# Flow specific methods for Spree::Variant
# Spree save all the prices inside Variant object. We choose to have a cache jsonb field named flow_data that will
# hold all important Flow sync data for specific experiences.
module Spree
  Variant.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :flow_data

    # after every save we sync product we generate sh1 checksums to update only when change happend
    after_save :sync_product_to_flow

    def experience
      flow_data['exp']
    end

    def experience=(value)
      flow_data['exp'] = value
    end

    # clears flow_data from the records
    def truncate_flow_data
      meta.delete(:flow_data)
      update_column(:meta, meta.to_json)
    end

    # upload product variant to Flow's Product Catalog
    def sync_product_to_flow
      # initial Spree seed will fail, so skip unless we have Flow data field
      return if !respond_to?(:flow_data) || FlowcommerceSpree::API_KEY.blank? || FlowcommerceSpree::API_KEY == 'test_key'

      return { error: 'Price is 0' } if price == 0

      # master is not sellable, if product has other variants
      # return { error: 'Master not sellable, if product has other variants' } if is_master? && product.variants.size > 1

      additional_attrs = {}
      attr_name = nil
      FlowcommerceSpree::Config.additional_attributes[self.class.name.tableize.tr('/', '_').to_sym].each do |attr_item|
        attr_name = attr_item[0]
        # Flow.io could require a different attribute name, as in case of Fulfil's :customs_description - it has the
        # export_name `:materials` for flow.io. That's why 1st we're checking if an export_name is defined for the
        # attribute.
        attr_flowcommerce_name = attr_item[1][:export_name] || attr_name
        export_required = attr_item[1][:export] == :required
        attr_value = __send__(attr_name)
        break if export_required && attr_value.blank?

        additional_attrs[attr_flowcommerce_name] = attr_value
      end

      return { error: "Variant with sku = #{sku} has no #{attr_name}" } if additional_attrs.blank?

      flow_item     = to_flowcommerce_item(additional_attrs)
      flow_item_sh1 = Digest::SHA1.hexdigest(flow_item.to_json)

      # skip if sync not needed
      return nil if flow_data&.[](:last_sync_sh1) == flow_item_sh1

      response = FlowcommerceSpree.client.items.put_by_number(FlowcommerceSpree::ORGANIZATION, sku, flow_item)
      self.flow_data ||= {}
      self.flow_data[:last_sync_sh1] = flow_item_sh1

      # after successful put, write cache
      update_column(:meta, meta.to_json)

      response
    rescue Net::OpenTimeout => e
      return { error: e.message }
    end

    def flow_prices(flow_exp)
      flow_data&.dig(:exp, flow_exp, :prices) || []
    end

    # returns price bound to local experience
    def flow_local_price(flow_exp)
      price_object = flow_prices(flow_exp)&.first
      amount = price_object&.[](:amount) || self.price
      currency = price_object&.[](:currency) || self.cost_currency
      Spree::Price.new(variant_id: self.id, currency: currency, amount: amount)
    end

    # creates object for flow api
    def to_flowcommerce_item(additional_attrs)
      # add product categories
      categories = []
      taxon = product.taxons.first
      current_taxon = taxon
      while current_taxon
        categories.unshift current_taxon.name
        current_taxon = current_taxon.parent
      end

      images = if (image = product.images.first || product.variant_images.first)
                 asset_host_scheme = ENV.fetch('ASSET_HOST_PROTOCOL', 'https')
                 asset_host = ENV.fetch('ASSET_HOST', 'staging.mejuri.com')
                 large_image_uri = URI(image.attachment(:large))
                 product_image_uri = URI(image.attachment.url(:product))
                 large_image_uri.scheme ||= asset_host_scheme
                 product_image_uri.scheme ||= asset_host_scheme
                 large_image_uri.host ||= asset_host
                 product_image_uri.host ||= asset_host

                 [{ url: large_image_uri.to_s, tags: ['checkout'] },
                  { url: product_image_uri.to_s, tags: ['thumbnail'] }]
               else
                 []
               end

      Io::Flow::V0::Models::ItemForm.new(
        number:      sku,
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
    def flow_import_item(item_hash, experience_key: nil)
      # If experience not specified, get it from the local hash of imported variant
      experience_key = item_hash.dig(:local, :experience, :key) unless experience_key
      self.flow_data ||= {}
      current_experience_meta = item_hash.delete(:local)
      # Do not repeatedly store Experience data - this is stored in Spree::Zones::Product
      current_experience_meta.delete(:experience)
      self.flow_data[:exp] ||= {}
      self.flow_data[:exp][experience_key] = current_experience_meta
      self.flow_data.merge!(item_hash)

      update_column(:meta, meta.to_json)
    end
  end
end
