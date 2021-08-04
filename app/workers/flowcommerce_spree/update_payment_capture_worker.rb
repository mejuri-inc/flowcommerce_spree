# frozen_string_literal: true

module FlowcommerceSpree
  class UpdatePaymentCaptureWorker < FlowIoWorker
    sidekiq_options retry: 3, queue: :flow_io

    def perform(order_number, capture = {})
      order = Spree::Order.find_by number: order_number
      raise 'Order has no payments' if order.payments.empty?

      FlowcommerceSpree::Webhooks::CaptureUpsertedV2.new({ capture: capture }.as_json)
                                                    .store_payment_capture(order, capture)
    end
  end
end
