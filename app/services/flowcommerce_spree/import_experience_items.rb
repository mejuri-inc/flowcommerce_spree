module FlowcommerceSpree
  class ImportExperienceItems
    def self.run(experience_key, client: FlowcommerceSpree.client, organization: ORGANIZATION)
      new(experience_key, client: client, organization: organization).run
    end

    def run
      page_size  = 100
      offset     = 0
      items      = []
      total = 0

      while offset == 0 || items.length == 100
        # show current list size
        @logger.info "\nGetting items: #{@experience_key.green}, rows #{offset} - #{offset + page_size}"

        begin
          items = @client.experiences
                         .get_items(@organization, experience: @experience_key, limit: page_size, offset: offset)
        rescue Io::Flow::V0::HttpClient::PreconditionException => _e
          break
        end

        offset += page_size
        log_str = ''

        items.each do |item|
          total += 1
          item_hash = item.to_hash
          next unless (variant = Spree::Variant.find_by(sku: item_hash.delete(:number)))

          # if item is not included, mark it in product as excluded regardless if excluded or restricted
          status_in_experience = item_hash.dig(:local, :status)
          unless status_in_experience == 'included'
            log_str << "[#{status_in_experience.red}]:"
            if (product = variant.product)
              product.flow_data ||= {}
              product.flow_data["#{@experience_key}.excluded"] = 1
              product.update_column(:meta, product.meta.to_json)
            end
          end

          variant.flow_import_item(item_hash, experience_key: @experience_key)

          log_str << "#{variant.sku}, "
        end
        @logger.info log_str
      end

      @logger.info "\nData for #{total.to_s.green} products was imported."
    end

    private

    def initialize(experience_key, client:, organization:)
      @client = client
      @experience_key = experience_key
      @logger = client.instance_variable_get(:@http_handler).logger
      @organization = organization
    end
  end
end
