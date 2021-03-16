# frozen_string_literal: true

module FlowcommerceSpree
  module Webhooks
    class ExperienceUpsertedV2
      attr_accessor :errors
      alias full_messages errors

      def self.process(data, opts = {})
        new(data, opts).process
      end

      def initialize(data, opts = {})
        @data = data
        @opts = opts
        @errors = []
      end

      def process
        experience = @data['experience']
        Spree::Zones::Product.find_or_initialize_by(name: experience['key'].titleize).store_flow_io_data(experience)
      end
    end
  end
end
