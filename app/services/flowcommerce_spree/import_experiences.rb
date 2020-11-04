module FlowcommerceSpree
  class ImportExperiences
    def self.run(client: FlowcommerceSpree.client, organization: ORGANIZATION, with_items: nil, refresher: nil)
      new(client: client, organization: organization, with_items: with_items, refresher: refresher).run
    end

    def run
      # we have to log start, so that another process does not start while this one is running
      @refresher.log_refresh!

      total = 0
      experiences = @client.experiences.get(@organization)

      experiences.each do |experience|
        experience_key = experience.key
        zone = Spree::Zones::Product.find_or_initialize_by(name: experience_key.titleize)
        zone.import_flowcommerce(experience, logger: @refresher.logger)

        ImportExperienceItems.run(experience_key, client: @client) if @with_items
      end

      # Log sync end time
      @refresher.log_refresh!(has_ended: true)
      total
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
