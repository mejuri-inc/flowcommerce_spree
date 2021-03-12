# frozen_string_literal: true

module FlowcommerceSpree
  # represents flow.io order syncing service
  # for easy integration we are currently passing:
  # - flow experience
  # - spree order
  # - current customer, if present as  @order.user
  #
  # example:
  #  flow_order = FlowcommerceSpree::OrderSync.new    # init flow-order object
  #    order: Spree::Order.last,
  #    experience: @flow_session.experience
  #    customer: @order.user
  #  flow_order.build_flow_request           # builds json body to be posted to flow.io api
  #  flow_order.synchronize!                 # sends order to flow
  class OrderSync # rubocop:disable Metrics/ClassLength
    FLOW_CENTER = 'default'

    attr_reader :order, :response

    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(order:, flow_session_id:)
      raise(ArgumentError, 'Experience not defined or not active') unless order&.zone&.flow_io_active_experience?

      @experience = order&.flow_io_experience_key
      @flow_session_id = flow_session_id
      @order = order
      @client = FlowcommerceSpree.client(
        default_headers: { "Authorization": "Session #{flow_session_id}" },
        authorization: nil
      )
    end

    # helper method to send complete order from Spree to flow.io
    def synchronize!
      return unless @order.zone&.flow_io_active_experience? && @order.state == 'cart' && @order.line_items.size > 0

      sync_body!
      write_response_in_cache

      @order.update_columns(total: @order.total, meta: @order.meta.to_json)
      refresh_checkout_token
      @checkout_token
    end

    def error
      @response['messages'].join(', ')
    end

    def error_code
      @response['code']
    end

    def error?
      @response&.[]('code') && @response&.[]('messages') ? true : false
    end

    # builds object that can be sent to api.flow.io to sync order data
    def build_flow_request
      @opts = { experience: @experience, expand: ['experience'] }
      @body = { items: @order.line_items.map { |line_item| add_item(line_item) } }

      try_to_add_customer

      return unless (flow_data = @order.flow_data['order'])

      @body[:selections] = flow_data['selections'].presence
      @body[:delivered_duty] = flow_data['delivered_duty'].presence
      @body[:attributes] = flow_data['attributes'].presence

      # discount on full order is applied
      @body[:discount] = { amount: @order.adjustment_total, currency: @order.currency } if @order.adjustment_total != 0
    end

    private

    def refresh_checkout_token
      root_url = url_helpers.root_url
      order_number = @order.number
      confirmation_url = "#{root_url}flow/order-completed?order=#{order_number}&t=#{@order.guest_token}"
      @checkout_token = FlowcommerceSpree.client.checkout_tokens.post_checkout_and_tokens_by_organization(
        FlowcommerceSpree::ORGANIZATION,
        discriminator: 'checkout_token_reference_form',
        order_number: order_number,
        session_id: @flow_session_id,
        urls: { continue_shopping: root_url,
                confirmation: confirmation_url,
                invalid_checkout: root_url }
      )&.id

      @order.flow_io_attribute_add('flow_return_url', confirmation_url)
      @order.flow_io_attribute_add('checkout_continue_shopping_url', root_url)
    end

    # if customer is defined, add customer info
    # it is possible to have order in Spree without customer info (new guest session)
    def try_to_add_customer
      return unless (customer = @order.user)

      address = nil
      customer_ship_address = customer.ship_address
      address = customer_ship_address if customer_ship_address&.country&.iso3 == @order.zone.flow_io_experience_country

      unless address
        user_profile_address = customer.user_profile&.address
        address = user_profile_address if user_profile_address&.country&.iso3 == @order.zone.flow_io_experience_country
      end

      @body[:customer] = { name: { first: address&.firstname,
                                   last: address&.lastname },
                           email: customer.email,
                           number: customer.flow_number,
                           phone: address&.phone }

      add_customer_address(address) if address
    end

    def add_customer_address(address)
      streets = []
      streets.push address.address1 if address&.address1.present?
      streets.push address.address2 if address&.address2.present?

      @body[:destination] = { streets: streets,
                              city: address&.city,
                              province: address&.state_name,
                              postal: address&.zipcode,
                              country: (address&.country&.iso3 || ''),
                              contact: @body[:customer] }

      @body[:destination].delete_if { |_k, v| v.nil? }
    end

    def sync_body!
      build_flow_request

      @use_get = false

      # use get if order is completed and closed
      @use_get = true if @order.flow_data.dig('order', 'submitted_at').present? || @order.state == 'complete'

      # do not use get if there is no local order cache
      @use_get = false unless @order.flow_data['order']

      if @use_get
        @response ||= @client.orders.get_by_number(ORGANIZATION, @order.number).to_hash
      else
        @response = @client.orders.put_by_number(ORGANIZATION, @order.number,
                                                 Io::Flow::V0::Models::OrderPutForm.new(@body), @opts).to_hash
      end
    end

    def add_item(line_item)
      variant    = line_item.variant
      price_root = variant.flow_data&.dig('exp', @experience, 'prices')&.[](0) || {}

      # create flow order line item
      { center: FLOW_CENTER,
        number: variant.sku,
        quantity: line_item.quantity,
        price: { amount: price_root['amount'] || variant.cost_price,
                 currency: price_root['currency'] || variant.cost_currency } }
    end

    # set cache for total order amount
    # written in flow_data field inside spree_orders table
    def write_response_in_cache
      if !@response || error?
        @order.flow_data.delete('order')
      else
        response_total = @response[:total]
        response_total_label = response_total&.[](:label)
        cache_total = @order.flow_data.dig('order', 'total', 'label')

        # return if total is not changed, no products removed or added
        return if @use_get && response_total_label == cache_total

        # update local order
        @order.total = response_total&.[](:amount)
        @order.flow_data.merge!('order' => @response)
      end
    end
  end
end
