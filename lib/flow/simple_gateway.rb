# frozen_string_literal: true

# Flow.io (2017)
# communicates with Flow payments API, easy access to session
# to basic shop frontend and backend needs
module Flow
  class SimpleGateway
    cattr_accessor :clear_zero_amount_payments

    def initialize(order)
      @order = order
    end

    # authorises credit card and prepares for capture
    def cc_authorization
      response = FlowcommerceSpree.client.authorizations.post(FlowcommerceSpree::ORGANIZATION, build_authorization_form)
      status_message = response.result.status.value
      status = status_message == ::Io::Flow::V0::Models::AuthorizationStatus.authorized.value

      store = { key: response.key,
                amount: response.amount,
                currency: response.currency,
                authorization_id: response.id }

      @order.flow_data['authorization'] = store
      @order.update_column(:meta, @order.meta.to_json)

      if self.class.clear_zero_amount_payments
        @order.payments.where(amount: 0, state: %w[invalid processing pending]).map(&:destroy)
      end

      ActiveMerchant::Billing::Response.new(status, status_message, { response: response }, authorization: store)
    rescue Io::Flow::V0::HttpClient::ServerError => e
      error_response(e)
    end

    private

    # if order is not in flow, we use local Spree settings
    def in_flow?
      @order.flow_order ? true : false
    end

    def build_authorization_form
      if in_flow?
        # we have order id so we allways use MerchantOfRecordAuthorizationForm
        ::Io::Flow::V0::Models::MerchantOfRecordAuthorizationForm.new('order_number': @order.flow_number,
                                                                      'currency': @order.flow_order.total.currency,
                                                                      'amount': @order.flow_order.total.amount,
                                                                      'token': cc_get_token)
      else
        # when not using Flow, we fall back to Spree default
        ::Io::Flow::V0::Models::DirectAuthorizationForm.new('currency': @order.currency,
                                                            'amount': @order.total,
                                                            'token': cc_get_token)
      end
    end

    # gets credit card token
    def cc_get_token
      cards = @order.credit_cards.select(&:gateway_customer_profile_id)
      raise StandardError, 'Credit card with token not found' unless cards.first

      cards.first.gateway_customer_profile_id
    end

    # we want to return errors in standardized format
    def error_response(exception_object)
      message = if exception_object.respond_to?(:body) && exception_object.body.length > 0
                  description = Oj.load(exception_object.body)['messages'].to_sentence
                  "#{exception_object.details}: #{description} (#{exception_object.code})"
                else
                  exception_object.message
                end

      ActiveMerchant::Billing::Response.new(false, message, exception: exception_object)
    end
  end
end
