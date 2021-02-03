# frozen_string_literal: true

module Spree
  OrderMailer.class_eval do
    # default from: ApplicationMailer::DEFAULT_FROM

    def refund_complete_email(web_hook_event)
      auth_id = web_hook_event.dig('refund', 'authorization', 'key')

      raise Flow::Error, 'authorization key not found in WebHookEvent [refund_capture_upserted_v2]' unless auth_id

      authorization = FlowcommerceSpree.client.authorizations.get_by_key FlowcommerceSpree::ORGANIZATION, auth_id

      refund_requested = web_hook_event['refund']['requested']
      @mail_to = authorization.customer.email
      @full_name = "#{authorization.customer.name.first} #{authorization.customer.name.last}"
      @amount = "#{refund_requested['amount']} #{refund_requested['currency']}"
      @number = authorization.order.number
      @order = Spree::Order.find_by number: @number

      mail(to: @mail_to, subject: "We refunded your order for ammount #{@amount}")
    end
  end
end
