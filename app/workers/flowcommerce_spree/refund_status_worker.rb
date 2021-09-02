# frozen_string_literal: true

module FlowcommerceSpree
  class RefundStatusWorker < FlowIoWorker
    sidekiq_options retry: 3, queue: :flow_io

    def perform(order_number, refund_key)
      response = FlowcommerceSpree.client.refunds.get_by_key(FlowcommerceSpree::ORGANIZATION, refund_key)
      response_status = response.status.value
      return if response_status == 'succeeded'

      raise "Refund with capture pending for order: #{order_number}, refund status: #{response_status}"
    end
  end
end
