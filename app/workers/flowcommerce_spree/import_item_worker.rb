# frozen_string_literal: true

module FlowcommerceSpree
  class ImportItemWorker
    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: :flow_io

    sidekiq_retries_exhausted do |message, exception|
      Rails.logger.warn("[!] FlowcommerceSpree::ImportItemWorker max attempts reached: #{message} - #{exception}")
      notification_setting = FlowcommerceSpree::Config.notification_setting
      return unless notification_setting[:slack].present?

      slack_message = "[#{Rails.env}] #{message}"
      Slack_client.chat_postMessage(channel: notification_setting[:slack][:channel], text: slack_message)
    end

    def perform(variant_sku)
      variant = Spree::Variant.find_by sku: variant_sku
      return unless variant

      FlowcommerceSpree::ImportItem.run(variant)
    end
  end
end
