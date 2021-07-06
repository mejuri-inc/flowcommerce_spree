# frozen_string_literal: true

module FlowcommerceSpree
  class UpdatePaymentCapture
    include Sidekiq::Worker
    # include FlowcommerceSpree::FlowIoWorker
    sidekiq_options retry: 3, queue: :flow_io

    sidekiq_retries_exhausted do |message, exception|
      Rails.logger.warn("[!] #{self.class} max attempts reached: #{message} - #{exception}")
      notification_setting = FlowcommerceSpree::Config.notification_setting
      return unless notification_setting[:slack].present?

      slack_message = "[#{Rails.env}] #{message}"
      Slack_client.chat_postMessage(channel: notification_setting[:slack][:channel], text: slack_message)
    end

    def perform(order_number, capture)
      order = Spree::Order.find_by number: order_number
      raise 'Order has no payments' if order.payments.empty?

      FlowcommerceSpree::Webhooks::CaptureUpsertedV2.new({ capture: capture }.as_json)
                                                    .store_payment_capture(order, capture)
    end
  end
end
