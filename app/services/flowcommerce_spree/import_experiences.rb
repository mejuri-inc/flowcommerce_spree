# frozen_string_literal: true

module FlowcommerceSpree
  # A service object to import the data for of flow.io Experience into Spree::Zones::Product
  class ImportExperiences
    def self.run(client: FlowcommerceSpree.client, organization: ORGANIZATION, with_items: nil, refresher: nil)
      new(client: client, organization: organization, with_items: with_items, refresher: refresher).run
    end

    def run
      # we have to log start, so that another process does not start while this one is running
      @refresher.log_refresh!

      @client.experiences.get(@organization).each do |experience|
        experience_key = experience.key
        zone = Spree::Zones::Product.find_or_initialize_by(name: experience_key.titleize)
        zone.store_flow_io_data(experience, logger: @refresher.logger)

        next @refresher.logger.info "Error: storing flow.io experience #{experience_key}" if zone.errors.any?

        ImportExperienceItems.run(zone, client: @client) if @with_items
      end

      # Log sync end time
      @refresher.log_refresh!(has_ended: true)
    end

    private

    def initialize(client:, organization:, with_items: nil, refresher: Refresher.new)
      @refresher = refresher
      @client = client
      @organization = organization
      @with_items = with_items
    end
  end
end
