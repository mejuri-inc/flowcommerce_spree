# frozen_string_literal: true

module Spree
  module Zones
    Product.class_eval do
      after_update :update_on_flow, if: ->{ flow_data['key'].present? }
      before_destroy :remove_on_flow, if: ->{ flow_data['key'].present? }

      def update_on_flow

      end

      def remove_on_flow
        client = FlowcommerceSpree::CLIENT
        client.experiences.delete_by_key(FlowcommerceSpree::ORGANIZATION, flow_data['key'])

        # Flowcommerce `delete_by_key` methods are always returning `nil`, that's why this hack of fetching
        # @http_handler from client. This handler is a LoggingHttpHandler, which got the http_client attr_reader
        # implemented specifically for this purpose.
        false if client.instance_variable_get(:@http_handler).http_client.error
      end
    end
  end
end
