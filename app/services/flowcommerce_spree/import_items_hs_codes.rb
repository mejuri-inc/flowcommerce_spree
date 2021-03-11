# frozen_string_literal: true

module FlowcommerceSpree
  # A service object to import the data for product variants belonging to a flow.io Experience
  class ImportItemsHsCodes
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
          items = @client.hs10.get(@organization, limit: page_size, offset: offset)
        rescue Io::Flow::V0::HttpClient::PreconditionException => e
          @logger.info "flow.io API error: #{e.message}"
          break
        end

        offset += page_size
        log_str = +''

        items.group_by { |hs_code| hs_code.item.number }.each do |item|
          total += 1

          variant_sku = item.first
          next unless (variant = Spree::Variant.find_by(sku: variant_sku))

          hs_code_data_list = item.last
          hs_code = hs_code_data_list&.first&.code&.[](0..5)
          variant.flow_data ||= {}
          variant.flow_data['hs_code'] = hs_code
          variant.update_column(:meta, variant.meta.to_json)
          log_str << "#{variant.sku}, "
        end
        @logger.info log_str
      end

      # @logger.info "\nUpdating Fulfil: #{@experience_key.green}"
      # VariantService.new.update_classification

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
  end
end
