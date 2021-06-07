# frozen_string_literal: true

module FlowcommerceSpree
  # A service object to import the data for product variants belonging to a flow.io Experience
  class ImportExperienceItems
    def self.run(zone, client: FlowcommerceSpree.client, organization: ORGANIZATION)
      new(zone, client: client, organization: organization).run
    end

    def run
      page_size  = 100
      offset     = 0
      items      = []
      total = 0

      while offset == 0 || items.length != 0
        # show current list size
        @logger.info "\nGetting items: #{@experience_key.green}, rows #{offset} - #{offset + page_size}"

        begin
          items = @client.experiences
                         .get_items(@organization, experience: @experience_key, limit: page_size, offset: offset)
        rescue Io::Flow::V0::HttpClient::PreconditionException => e
          @logger.info "flow.io API error: #{e.message}"
          break
        end

        offset += page_size
        log_str = +''

        items.each do |item|
          total += 1
          item_hash = item.to_hash
          next unless (variant = Spree::Variant.find_by(sku: item_hash.delete(:number)))

          status_in_experience = item_hash.dig(:local, :status)

          if status_in_experience != 'included'
            log_str << "[#{status_in_experience.red}]:"
          else # If at least a variant is included in experience, include the product too
            adjust_product_zone(variant)
          end

          variant.flow_import_item(item_hash, experience_key: @experience_key)

          log_str << "#{variant.sku}, "
        end
        @logger.info log_str
      end

      @logger.info "\nData for #{total.to_s.green} products was imported."
    end

    private

    def initialize(zone, client:, organization:)
      @client = client
      @experience_key = zone.flow_io_experience
      @logger = client.instance_variable_get(:@http_handler).logger
      @organization = organization
      @zone = zone
    end

    def adjust_product_zone(variant)
      return unless (product = variant.product)

      zone_ids = product.zone_ids || []
      zone_id_string = @zone.id.to_s
      return if zone_ids.include?(zone_id_string)

      zone_ids << zone_id_string
      product.zone_ids = zone_ids
      product.update_columns(meta: product.meta.to_json)
    end
  end
end
