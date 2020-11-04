module Spree
  OrderMailer.class_eval do
    # default from: ApplicationMailer::DEFAULT_FROM

    def refund_complete_email web_hook_event
      auth_id = web_hook_event.dig('refund', 'authorization', 'key')

      raise Flow::Error.new('authorization key not found in WebHookEvent [refund_capture_upserted_v2]') unless auth_id

      authorization = FlowcommerceSpree.client.authorizations.get_by_key FlowcommerceSpree::ORGANIZATION, auth_id

      @mail_to   = authorization.customer.email
      @full_name = '%s %s' % [authorization.customer.name.first, authorization.customer.name.last]
      @amount    = '%s %s' % [web_hook_event['refund']['requested']['amount'], web_hook_event['refund']['requested']['currency']]
      @number    = authorization.order.number
      @order     = Spree::Order.find_by number: @number

      mail({ to:      @mail_to,
             subject: 'We refunded your order for ammount %s' % @amount })
    end
  end
end
