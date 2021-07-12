# frozen_string_literal: true

module FlowcommerceSpree
  class FlowIoWorker
    include Sidekiq::Worker

    sidekiq_retries_exhausted do |message, exception|
      Rails.logger.warn("[!] #{self.class} max attempts reached: #{message} - #{exception}")
      notification_setting = FlowcommerceSpree::Config.notification_setting
      return unless notification_setting[:slack].present?

      slack_message = "[#{Rails.env}] #{message}"
      Slack_client.chat_postMessage(channel: notification_setting[:slack][:channel], text: slack_message)
    end
  end
end
