# frozen_string_literal: true

module FlowcommerceSpree
  module Webhooks
    class CaptureUpsertedV2
      attr_reader :errors
      alias full_messages errors

      def self.process(data)
        new(data).process
      end

      def initialize(data)
        @data = data
        @errors = []
      end

      def process
        errors << { message: 'Capture param missing' } && (return self) unless (capture = @data['capture']&.to_hash)

        order_number = capture.dig('authorization', 'order', 'number')
        errors << { message: 'Order number param missing' } && (return self) unless order_number

        if (order = Spree::Order.find_by(number: order_number))
          if order.payments.any?
            store_payment_capture(order, capture)
          else
            FlowcommerceSpree::UpdatePaymentCaptureWorker.perform_in(1.minute, order.number, capture)
            order
          end
        else
          errors << { message: "Order #{order_number} not found" }
          self
        end
      end

      def store_payment_capture(order, capture)
        upsert_order_captures(order, capture)
        map_payment_captures_to_spree(order)
        order
      end

      private

      def upsert_order_captures(order, capture)
        order.flow_data ||= {}
        order.flow_data['captures'] ||= []
        order_captures = order.flow_data['captures']
        order_captures.delete_if { |c| c['id'] == capture['id'] }
        order_captures << capture
        order.update_column(:meta, order.meta.to_json)
      end

      def map_payment_captures_to_spree(order)
        payments = order.flow_io_payments
        order.flow_data['captures']&.each do |c|
          next unless c['status'] == 'succeeded'

          payment = map_payment(payments, c, order)
          next unless payment

          payment.capture_events.create!(amount: c['amount'], meta: { 'flow_data' => { 'id' => c['id'] } })
          return if payment.completed? || payment.capture_events.sum(:amount) < payment.amount

          payment.complete
        end
        return if order.completed?
        return unless order.flow_io_captures_sum >= order.flow_io_total_amount && order.flow_io_balance_amount <= 0

        FlowcommerceSpree::OrderUpdater.new(order: order).finalize_order
      end

      def map_payment(payments, capture, order)
        payments.present? ? captured_payment(payments, capture) : get_payments_from_flow(order, capture)
      end

      def captured_payment(flow_order_payments, capture)
        auth = capture.dig('authorization', 'id')

        return unless flow_order_payments&.find { |p| p['reference'] == auth }

        return unless (payment = Spree::Payment.find_by(response_code: auth))

        return if Spree::PaymentCaptureEvent.where("meta -> 'flow_data' ->> 'id' = ?", capture['id']).exists?

        payment
      end

      def get_payments_from_flow(order, capture)
        flow_io_order ||= FlowcommerceSpree.client.orders
                                           .get_by_number(FlowcommerceSpree::ORGANIZATION, order.number).to_hash
        return unless flow_io_order[:payments]

        order.flow_data['order']['payments'] = flow_io_order[:payments]
        attrs_to_update = { meta: order.meta.to_json }
        attrs_to_update.merge!(order.prepare_flow_addresses)
        order.update_columns(attrs_to_update)
        payment = order.payments.first
        payment.response_code = capture.dig('authorization', 'id')
        payment.identifier = capture.dig('authorization', 'id')
        payment.save

        payment
      end
    end
  end
end
