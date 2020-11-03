module FlowcommerceSpree
  class ImportExperiences
    def self.run(client: nil, organization: nil)
      new(client: client, organization: organization).run
    end

    def run
      # we have to log start, so that another process does not start while this one is running
      ApiRefresh.log_refresh!

      total = 0
      experiences = @client.experiences.get(@organization)

      experiences.each do |experience|
        experience_key = experience.key
        zone = Spree::Zones::Product.find_or_initialize_by(name: experience_key.titleize)
        zone.import_flowcommerce(experience)

        page_size  = 100
        offset     = 0
        items      = []

        while offset == 0 || items.length == 100
          # show current list size
          puts "\nGetting items: #{experience_key.green}, rows #{offset} - #{offset + page_size}"

          begin
            items = @client.experiences
                           .get_items(@organization, experience: experience_key, limit: page_size, offset: offset)
          rescue Io::Flow::V0::HttpClient::PreconditionException => e
            puts "#{e.message}"
            break
          end

          offset += page_size

          items.each do |item|
            total += 1
            item_hash = item.to_hash
            next unless (variant = Spree::Variant.find_by(sku: item_hash.delete(:number)))

            # if item is not included, mark it in product as excluded regardless if excluded or restricted
            status_in_experience = item_hash.dig(:local, :status)
            unless status_in_experience == 'included'
              print "[#{status_in_experience.red}]:"
              if (product = variant.product)
                product.flow_data ||= {}
                product.flow_data["#{experience_key}.excluded"] = 1
                product.update_column(:meta, product.meta.to_json)
              end
            end

            variant.flow_import_item(item_hash, experience_key: experience_key)

            print "#{variant.sku}, "
          end
        end
      end

      # Log sync end time
      ApiRefresh.log_refresh!(has_ended: true)
      total
    end

    private

    def initialize(client: CLIENT, organization: ORGANIZATION)
      @client = client
      @organization = organization
    end
  end
end
