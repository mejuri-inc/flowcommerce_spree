# frozen_string_literal: true

# Communicates with flow.io API, easy access
# to basic shop frontend and backend needs
module FlowcommerceSpree
  module ExperienceService
    extend self

    def all(no_world = nil)
      experiences = fetch_from_flow
      no_world ? experiences.reject { |exp| exp.key == 'world' } : experiences
    end

    def keys
      all.map(&:key)
    end

    def get(key)
      all.each do |exp|
        return exp if exp.key == key
      end
      nil
    end

    def default
      FlowcommerceSpree::ExperienceService
        .all.select { |exp| exp.key.downcase == ENV.fetch('FLOW_BASE_COUNTRY').downcase }.first
    end

    private

    def fetch_from_flow
      FlowcommerceSpree.client.experiences.get ORGANIZATION

      # work with active axperiences only
      # experiences = experiences.select { |it| it.status.value == 'active' }
    end
  end
end
