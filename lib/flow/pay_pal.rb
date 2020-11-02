# Flow.io (2017)
# communicates with flow api to synchronize Spree order with PayPal

module Flow::PayPal
  extend self

  def get_id(order)
    if order.flow_order
      # get PayPal ID using Flow api
      body = {
        # discriminator: 'merchant_of_record_payment_form',
        method:        'paypal',
        order_number:  order.number,
        amount:        order.flow_order.total.amount,
        currency:      order.flow_order.total.currency,
      }

      # FlowcommerceSpree::Api.run :post, '/:organization/payments', {}, body
      form     = ::Io::Flow::V0::Models::MerchantOfRecordPaymentForm.new body
      FlowcommerceSpree::CLIENT.payments.post FlowcommerceSpree::ORGANIZATION, form
    else
      # to do
      raise 'PayPal only supported while using flow'
    end
  end
end
