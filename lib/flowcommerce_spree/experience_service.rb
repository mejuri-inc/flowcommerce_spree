# frozen_string_literal: true

# Communicates with flow.io API, easy access
# to basic shop frontend and backend needs
module FlowcommerceSpree
  module ExperienceService
    extend self

    def all(no_world = nil)
      experiences = get_from_flow
      no_world ? experiences.select { |exp| exp.key != 'world' } : experiences
    end

    def keys
      all.map { |el| el.key }
    end

    def get(key)
      all.each do |exp|
        return exp if exp.key == key
      end
      nil
    end

    def get_by_subcatalog_id(subcatalog_id)
      get_from_flow.each do |experince|
        return experince if experince.subcatalog.id == subcatalog_id
      end

      nil
    end

    def compact
      all.map { |exp| [exp.country, exp.key, exp.name] }
    end

    def default
      FlowcommerceSpree::ExperienceService.all.select { |exp| exp.key.downcase == ENV.fetch('FLOW_BASE_COUNTRY').downcase }.first
    end

    private

    def get_from_flow
      # return cached_experinces if cache_valid?

      experiences = FlowcommerceSpree.client.experiences.get ORGANIZATION

      # work with active axperiences only
      # experiences = experiences.select { |it| it.status.value == 'active' }

      # @cache = [experiences, Time.now]
      experiences
    end

    def cache_valid?
      # cache experinces in worker memory for 1 minute
      @cache && @cache[1] > Time.now.ago(1.minute)
    end

    def cached_experinces
      @cache[0]
    end
  end
end
