# frozen_string_literal: true

module FlowcommerceSpree
  class RefundStatusWorker < FlowIoWorker
    sidekiq_options retry: 3, queue: :flow_io

    def perform(order, refund_key)
      response = FlowcommerceSpree.client.refunds.request_refund_status(refund_key)
      pending_captures = response.captures.find_all { |cap| cap.capture.status.value != 'succeeded' }
      return if pending_captures.blank?

      raise "Refund with capture pending for order: #{order.id}, refund status: #{response.status}"
    end
  end
end