# frozen_string_literal: true

# Flow specific methods for Spree::Variant
# Spree save all the prices inside Variant object. We choose to have a cache jsonb field named flow_data that will
# hold all important Flow sync data for specific experiences.
module Spree
  module FlowIoVariantDecorator
    REST_OF_WORLD = 'ROW'

    def self.prepended(base)
      base.serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

      base.store_accessor :meta, :flow_data

      # after every save we sync product we generate sh1 checksums to update only when change happend
      base.after_save :sync_product_to_flow
    end

    def experiences
      flow_data&.[]('exp')
    end

    def add_flow_io_experience_data(exp, value)
      raise ArgumentError, 'Value should be a hash' unless value.is_a?(Hash)

      self.flow_data = flow_data || {}
      self.flow_data['exp'] ||= {} # rubocop:disable Style/RedundantSelf
      self.flow_data['exp'][exp] = value # rubocop:disable Style/RedundantSelf
    end

    # clears flow_data from the records
    def truncate_flow_data
      flow_data&.[]('exp')&.keys&.each do |exp_key|
        break unless (product = self.product)

        remove_experience_from_product(exp_key, product)
      end

      meta.delete(:flow_data)
      update_column(:meta, meta.to_json)
    end

    def remove_experience_from_product(exp_key, product)
      return unless (zone = Spree::Zones::Product.find_by(name: exp_key.titleize))

      zone_ids = product.zone_ids || []
      zone_id_string = zone.id.to_s
      return unless zone_ids.include?(zone_id_string)

      product.zone_ids = zone_ids - [zone_id_string]
      product.update_columns(meta: product.meta.to_json)
    end

    def sync_flow_info?
      if FlowcommerceSpree::API_KEY.blank? || FlowcommerceSpree::API_KEY == 'test_key'
        return { error: 'Api Keys not configured' }
      end
      return { error: 'Price is 0' } if price == 0
      return { error: 'Country of Origin is empty.' } unless country_of_origin
    end

    # upload product variant to Flow's Product Catalog
    def sync_product_to_flow
      error = sync_flow_info?
      return error if error.present?

      update_flow_data
    end

    def update_flow_data
      additional_attrs = {}
      attr_name = nil
      export_required = false
      FlowcommerceSpree::Config.additional_attributes[self.class.name.tableize.tr('/', '_').to_sym]&.each do |attr_item|
        attr_name = attr_item[0]
        # Flow.io could require a different attribute name, as in case of Fulfil's :customs_description - it has the
        # export_name `:materials` for flow.io. That's why 1st we're checking if an export_name is defined for the
        # attribute.
        attr_flowcommerce_name = attr_item[1][:export_name] || attr_name
        export_required = attr_item[1][:export] == :required
        attr_value = __send__(attr_name)
        break if export_required && attr_value.blank?

        additional_attrs[attr_flowcommerce_name] = attr_value if attr_value
      end

      if export_required && additional_attrs[attr_value].blank?
        return { error: "Variant with sku = #{sku} has no #{attr_name}" }
      end

      flow_item     = to_flowcommerce_item(additional_attrs)
      flow_item_sh1 = Digest::SHA1.hexdigest(flow_item.to_json)

      # skip if sync not needed
      return { error: 'Synchronization not needed' } if flow_data&.[](:last_sync_sh1) == flow_item_sh1

      response = FlowcommerceSpree.client.items.put_by_number(FlowcommerceSpree::ORGANIZATION, sku, flow_item)
      self.flow_data ||= {}
      self.flow_data[:last_sync_sh1] = flow_item_sh1

      # after successful put, write cache
      update_column(:meta, meta.to_json)

      FlowcommerceSpree::ImportItemWorker.perform_async(sku)

      response
    rescue Net::OpenTimeout => e
      { error: e.message }
    end

    def flow_prices(flow_exp)
      flow_data&.dig(:exp, flow_exp, :prices) || []
    end

    # returns price bound to local experience
    def flow_local_price(flow_exp)
      price_object = flow_prices(flow_exp)&.first
      amount = price_object&.[](:amount) || price
      currency = price_object&.[](:currency) || cost_currency
      Spree::Price.new(variant_id: id, currency: currency, amount: amount)
    end

    def price_in_zone(currency, product_zone)
      flow_experience_key = product_zone&.flow_data&.[]('key')
      return flow_local_price(flow_experience_key) if flow_experience_key.present?

      price_in(currency)
    end

    def all_prices_in_zone(product_zone)
      all_prices = prices.map { |price| parse_price(price) }

      flow_experience_key = product_zone&.flow_io_experience
      return all_prices if flow_experience_key.blank?

      flow_price = flow_local_price(flow_experience_key)
      all_prices << parse_price(flow_price)
      all_prices
    end

    def all_prices(zones)
      countries = {}

      zones.each do |zone|
        prices = create_prices_for_available_currencies(zone)
        add_prices_to_countries(prices, countries, zone.countries) unless prices.empty?

        flow_experience_key = zone&.flow_io_experience
        next if flow_experience_key.blank?

        add_flow_prices(flow_experience_key, countries, zone.flow_io_experience_country)
      end

      countries
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
        number: sku,
        locale: 'en_US',
        language: 'en',
        name: product.name,
        description: product.description,
        currency: cost_currency,
        price: price.to_f,
        images: images,
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
        product_slug: product.slug
      }.select { |_k, v| v.present? }
    end

    # gets flow catalog item, and imports it
    # called from flow:sync_localized_items rake task
    def flow_import_item(item_hash, experience_key: nil)
      # If experience not specified, get it from the local hash of imported variant
      experience_key ||= item_hash.dig(:local, :experience, :key)
      current_experience_meta = item_hash.delete(:local)

      # Do not repeatedly store Experience data - this is stored in Spree::Zones::Product
      current_experience_meta.delete(:experience)
      add_flow_io_experience_data(experience_key, current_experience_meta)
      self.flow_data.merge!(item_hash)

      update_column(:meta, meta.to_json)
    end

    Spree::Variant.prepend(self) if Spree::Variant.included_modules.exclude?(self)

    private

    def create_prices_for_available_currencies(zone)
      all_prices = []

      zone.available_currencies.each do |currency|
        price = prices.find_by(currency: currency)
        all_prices << parse_price(price) unless price.nil?
      end

      all_prices
    end

    def add_prices_to_countries(prices, countries, zone_countries)
      if zone_countries.empty?
        countries[REST_OF_WORLD] = prices
      else
        add_prices_for_each_country(zone_countries, prices, countries)
      end
    end

    def add_prices_for_each_country(zone_countries, prices, countries)
      zone_countries.each do |country|
        countries[country.iso] = prices
      end
    end

    def add_flow_prices(flow_experience_key, countries, country_iso)
      flow_price = flow_local_price(flow_experience_key)
      countries[country_iso] = parse_price(flow_price)
    end

    def parse_price(price)
      { currency: price.currency, amount: (price.amount&.round || 0).to_s }
    end
  end
end
