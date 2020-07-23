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
      auth_form      = get_authorization_form
      response       = FlowCommerce.instance.authorizations.post(Flow::ORGANIZATION, auth_form)
      status_message = response.result.status.value
      status         = status_message == ::Io::Flow::V0::Models::AuthorizationStatus.authorized.value

      store = {
                     key: response.key,
                  amount: response.amount,
                currency: response.currency,
        authorization_id: response.id
      }

      @order.update_column :flow_data, @order.flow_data.merge('authorization': store)

      if self.class.clear_zero_amount_payments
        @order.payments.where(amount:0, state: ['invalid', 'processing', 'pending']).map(&:destroy)
      end

      ActiveMerchant::Billing::Response.new(status, status_message, { response: response }, { authorization: store })
    rescue Io::Flow::V0::HttpClient::ServerError => exception
      error_response(exception)
    end

    # capture authorised funds
    def cc_capture
      # GET /:organization/authorizations, order_number: abc
      data = @order.flow_data['authorization']

      raise ArgumentError, 'No Authorization data, please authorize first' unless data

      capture_form = ::Io::Flow::V0::Models::CaptureForm.new(data)
      response     = FlowCommerce.instance.captures.post(Flow::ORGANIZATION, capture_form)

      if response.id
        @order.update_column :flow_data, @order.flow_data.merge('capture': response.to_hash)
        @order.flow_finalize!

        ActiveMerchant::Billing::Response.new true, 'success', { response: response }
      else
        ActiveMerchant::Billing::Response.new false, 'error', { response: response }
      end
    rescue => exception
      error_response(exception)
    end

    def cc_refund
      raise ArgumentError, 'capture info is not available' unless @order.flow_data['capture']

      # we allways have capture ID, so we use it
      refund_data = { capture_id: @order.flow_data['capture']['id'] }
      refund_form = ::Io::Flow::V0::Models::RefundForm.new(refund_data)
      response    = FlowCommerce.instance.refunds.post(Flow::ORGANIZATION, refund_form)

      if response.id
        @order.update_column :flow_data, @order.flow_data.merge('refund': response.to_hash)
        ActiveMerchant::Billing::Response.new true, 'success', { response: response }
      else
        ActiveMerchant::Billing::Response.new false, 'error', { response: response }
      end
    rescue => exception
      error_response(exception)
    end

    private

    # if order is not in flow, we use local Spree settings
    def in_flow?
      @order.flow_order ? true : false
    end

    def get_authorization_form
      if in_flow?
        # we have order id so we allways use MerchantOfRecordAuthorizationForm
        ::Io::Flow::V0::Models::MerchantOfRecordAuthorizationForm.new({
          'order_number':  @order.flow_number,
          'currency':      @order.flow_order.total.currency,
          'amount':        @order.flow_order.total.amount,
          'token':         cc_get_token,
        })
      else
        # when not using Flow, we fall back to Spree default
        ::Io::Flow::V0::Models::DirectAuthorizationForm.new({
          'currency':      @order.currency,
          'amount':        @order.total,
          'token':         cc_get_token,
        })
      end
    end

    # gets credit card token
    def cc_get_token
      cards = @order.credit_cards.select{ |cc| cc.gateway_customer_profile_id }
      raise StandardError.new('Credit card with token not found') unless cards.first

      cards.first.gateway_customer_profile_id
    end

    # we want to return errors in standardized format
    def error_response(exception_object, message=nil)
      message = if exception_object.respond_to?(:body) && exception_object.body.length > 0
        description  = JSON.load(exception_object.body)['messages'].to_sentence
        '%s: %s (%s)' % [exception_object.details, description, exception_object.code]
      else
        exception_object.message
      end

      ActiveMerchant::Billing::Response.new(false, message, exception: exception_object)
    end
  end
end
