# frozen_string_literal: true

module Spree
  module Zones
    Product.class_eval do
      after_update :update_on_flow, if: ->{ flow_data['key'].present? }
      before_destroy :remove_on_flow, if: ->{ flow_data['key'].present? }

      def available_currencies
        ((currencies || []) + [flow_data&.[]('currency')]).compact.uniq
      end

      def update_on_flow

      end

      def remove_on_flow
        client = FlowcommerceSpree.client
        client.experiences.delete_by_key(FlowcommerceSpree::ORGANIZATION, flow_data['key'])

        # Flowcommerce `delete_by_key` methods are always returning `nil`, that's why this hack of fetching
        # @http_handler from client. This handler is a LoggingHttpHandler, which got the http_client attr_reader
        # implemented specifically for this purpose.
        false if client.instance_variable_get(:@http_handler).http_client.error
      end

      def store_flow_io_data(received_experience, logger: FlowcommerceSpree.logger)
        self.flow_data = received_experience.is_a?(Hash) ? received_experience : received_experience.to_hash
        self.status = flow_data['status']

        if new_record? && update_attributes(meta: meta, status: status, kind: 'country')
          logger.info "\nNew flow.io experience imported as product zone: #{name}"
        elsif update_columns(meta: meta.to_json, status: status, kind: 'country')
          logger.info "\nProduct zone `#{name}` has been updated from flow.io"
        end

        self
      end
    end
  end
end
