# frozen_string_literal: true

module FlowcommerceSpree
  module Webhooks
    class FraudStatusChanged
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
        order_number = @data.dig('order', 'number')
        errors << { message: 'Order number param missing' } && (return self) unless order_number

        order = Spree::Order.find_by(number: order_number)
        errors << { message: "Order #{order_number} not found" } && (return self) unless order

        if @data['status'] == 'declined'
          order.update_columns(fraudulent: true)
          order.cancel!
        end

        order
      end
    end
  end
end
