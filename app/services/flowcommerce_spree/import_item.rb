# frozen_string_literal: true

module FlowcommerceSpree
  # A service object to import the data for product variants belonging to a flow.io Experience
  class ImportItem
    def self.run(variant, client: FlowcommerceSpree.client, organization: ORGANIZATION)
      new(variant, client: client, organization: organization).run
    end

    def run
      @client.experiences.get(@organization, status: 'active').each do |experience|
        experience_key = experience.key
        zone = Spree::Zones::Product.find_by(name: experience_key.titleize)
        next unless zone

        import_data(zone)
      end
    end

    private

    def initialize(variant, client:, organization:)
      @client = client
      @logger = client.instance_variable_get(:@http_handler).logger
      @organization = organization
      @variant = variant
    end

    def import_data(zone)
      item = begin
               @client.experiences.get_items_by_number(@organization, @variant.sku, experience: zone.flow_io_experience)
             rescue Io::Flow::V0::HttpClient::PreconditionException => e
               @logger.info "flow.io API error: #{e.message}"
             end
      return unless item

      item_hash = item.to_hash
      status_in_experience = item_hash.dig(:local, :status)

      @variant.product&.adjust_zone(zone) unless status_in_experience == 'included'

      @variant.flow_import_item(item_hash, experience_key: @experience_key)

      @logger.info "[#{@variant.sku} - #{@experience_key}] Variant experience imported successfully."
    end
  end
end
