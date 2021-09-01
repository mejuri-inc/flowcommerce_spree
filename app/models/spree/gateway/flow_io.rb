# frozen_string_literal: true

# Flow.io (2017)
# adapter for Spree that talks to activemerchant_flow
module Spree
  class Gateway
    class FlowIo < Gateway
      REFUND_VALID_STATES = %w[succeeded pending].freeze
      REFUND_SUCCESS = 'succeeded'
      REFUND_PENDING = 'pending'

      def provider_class
        self.class
      end

      def actions
        %w[capture authorize purchase refund void]
      end

      # if user wants to force auto capture
      def auto_capture?
        false
      end

      def payment_profiles_supported?
        false
      end

      def method_type
        'flow_io_gateway'
      end

      def preferences
        {}
      end

      def supports?(source)
        # flow supports credit cards
        source.class == Spree::CreditCard
      end

      def authorize(_amount, _payment_method, options = {})
        order = load_order options
        order.cc_authorization
      end

      def refund(payment, amount, _options = {})
        response = request_refund_store_result(payment.order, amount)
        map_refund_to_payment(response, payment.order) if response.success?
        response
      rescue StandardError => e
        ActiveMerchant::Billing::Response.new(false, e.to_s, {}, {})
      end

      def cancel(authorization)
        original_payment = Spree::Payment.find_by(response_code: authorization)
        response = request_refund_store_result(original_payment.order, original_payment.amount)
        map_refund_to_payment(response, original_payment.order) if response.success?
        response
      rescue StandardError => e
        ActiveMerchant::Billing::Response.new(false, e.to_s, {}, {})
      end

      def void(authorization_id, _source, options = {})
        amount = (options[:subtotal] + options[:shipping]) * 0.01
        reversal_form = Io::Flow::V0::Models::ReversalForm.new(key: options[:order_id],
                                                               authorization_id: authorization_id,
                                                               amount: amount,
                                                               currency: options[:currency])
        FlowcommerceSpree.client.reversals.post(FlowcommerceSpree::ORGANIZATION, reversal_form)
      end

      def create_profile(payment)
        # payment.order.state
        @credit_card = payment.source

        profile_ensure_payment_method_is_present!
        create_flow_cc_profile!
      end

      def credit(payment, credit_amount)
        request_refund_store_result(payment.order, credit_amount)
      rescue StandardError => e
        ActiveMerchant::Billing::Response.new(false, e.to_s, {}, {})
      end

      private

      def request_refund_store_result(order, amount)
        refund_form = Io::Flow::V0::Models::RefundForm.new(order_number: order.number,
                                                           amount: amount,
                                                           currency: order.currency)
        response = FlowcommerceSpree.client.refunds.post(FlowcommerceSpree::ORGANIZATION, refund_form)
        response_status = response.status.value
        if REFUND_VALID_STATES.include? response_status
          add_refund_to_order(response, order)
          schedule_status_check(response, order)
          ActiveMerchant::Billing::Response.new(true,
                                                REFUND_SUCCESS,
                                                response.to_hash,
                                                authorization: response.authorization.id)
        else
          ActiveMerchant::Billing::Response.new(false, "Partial refund fail. Details: #{response_status}", {}, {})
        end
      end

      def schedule_status_check(response, order)
        return if response.status.value != REFUND_PENDING

        Rails.logger.warn("[!] #{self.class} refund request without succeeded status.
        Order: #{order.id}, refund capture status: #{response.captures.first.capture.status.value}")
        FlowcommerceSpree::RefundStatusWorker.perform_async(order.number, response.key)
      end

      def add_refund_to_order(response, order)
        order.flow_data ||= {}
        order.flow_data['refunds'] ||= []
        order_refunds = order.flow_data['refunds']
        order_refunds.delete_if { |r| r['id'] == response.id }
        order_refunds << response.to_hash
        order.update_column(:meta, order.meta.to_json)
      end

      def map_refund_to_payment(response, order)
        original_payment = Spree::Payment.find_by(response_code: response.authorization)
        payment = order.payments.create!(state: 'completed',
                                         response_code: response.authorization,
                                         payment_method_id: original_payment&.payment_method_id,
                                         amount: - response.params['amount'].to_f,
                                         source: original_payment)

        # For now this additional update is overwriting the generated identifier with flow.io payment identifier.
        # TODO: Check and possibly refactor in Spree 3.0, where the `before_create :set_unique_identifier`
        # has been removed.
        payment.update_column(:identifier, response.params['id'])
      end

      # hard inject Flow as payment method unless defined
      def profile_ensure_payment_method_is_present!
        return if @credit_card.payment_method_id

        flow_payment_method = Spree::PaymentMethod.find_by(active: true, type: 'Spree::Gateway::FlowIo')
        @credit_card.payment_method_id = flow_payment_method.id if flow_payment_method
      end

      # create payment profile with Flow and tokenize Credit Card
      def create_flow_cc_profile!
        return if @credit_card.gateway_customer_profile_id
        return unless @credit_card.verification_value

        # build credit card hash
        data = {}
        data[:number]           = @credit_card.number
        data[:name]             = @credit_card.name
        data[:cvv]              = @credit_card.verification_value
        data[:expiration_year]  = @credit_card.year.to_i
        data[:expiration_month] = @credit_card.month.to_i

        # tokenize with Flow
        # rescue Io::Flow::V0::HttpClient::ServerError
        card_form = ::Io::Flow::V0::Models::CardForm.new(data)
        result    = FlowcommerceSpree.client.cards.post(::FlowcommerceSpree::ORGANIZATION, card_form)

        @credit_card.update_column :gateway_customer_profile_id, result.token
      end

      def load_order(options)
        order_number = options[:order_id].split('-').first
        spree_order  = Spree::Order.find_by number: order_number
        ::Flow::SimpleGateway.new spree_order
      end
    end
  end
end
