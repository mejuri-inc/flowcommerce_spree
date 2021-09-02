# frozen_string_literal: true

module FlowcommerceSpree
  # represents flow.io order syncing service
  class OrderSync
    FLOW_CENTER = 'default'

    attr_reader :order, :response

    # @param [Object] order
    # @param [String] flow_session_id
    def initialize(order:, flow_session_id:)
      raise(ArgumentError, 'Experience not defined or not active') unless order&.zone&.flow_io_active_experience?

      @experience = order.flow_io_experience_key
      @flow_session_id = flow_session_id
      @order = order
      @client = FlowcommerceSpree.client(default_headers: { "Authorization": "Session #{flow_session_id}" },
                                         authorization: nil)
    end

    # helper method to send complete order from Spree to flow.io
    def synchronize!
      return unless @order.state == 'cart' && @order.line_items.size > 0

      sync_body!
      write_response_to_order

      @order.update_columns(total: @order.total, meta: @order.meta.to_json)
      refresh_checkout_token
    end

    def error?
      @response&.[]('code') && @response&.[]('messages') ? true : false
    end

    private

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

    def refresh_checkout_token
      order_number = @order.number
      root_url = Rails.application.routes.url_helpers.root_url
      root_url_with_locale = "#{root_url}#{@order.try(:locale_path)}"
      confirmation_url = "#{root_url}flow/order-completed?order=#{order_number}&t=#{@order.guest_token}"
      @order.flow_io_attribute_add('flow_return_url', confirmation_url)
      @order.flow_io_attribute_add('checkout_continue_shopping_url', root_url_with_locale)

      FlowcommerceSpree.client.checkout_tokens.post_checkout_and_tokens_by_organization(
        FlowcommerceSpree::ORGANIZATION, discriminator: 'checkout_token_reference_form',
                                         order_number: order_number,
                                         session_id: @flow_session_id,
                                         urls: { continue_shopping: root_url_with_locale,
                                                 confirmation: confirmation_url,
                                                 invalid_checkout: root_url_with_locale }
      )&.id
    end

    # if customer is defined, add customer info
    # it is possible to have order in Spree without customer info (new guest session)
    def try_to_add_customer
      return unless (customer = @order.user)

      address = nil
      customer_ship_address = customer.ship_address
      address = customer_ship_address if customer_ship_address&.country&.iso3 == @order.zone.flow_io_experience_country

      customer_profile = customer.user_profile
      unless address
        user_profile_address = customer_profile&.address
        address = user_profile_address if user_profile_address&.country&.iso3 == @order.zone.flow_io_experience_country
      end

      @body[:customer] = { name: { first: address&.firstname || customer_profile&.first_name,
                                   last: address&.lastname || customer_profile&.last_name },
                           email: customer.email,
                           number: customer.flow_number,
                           phone: address&.phone }

      add_customer_address(address) if address
    end

    def add_customer_address(address)
      streets = []
      streets.push address.address1 if address.address1.present?
      streets.push address.address2 if address.address2.present?

      @body[:destination] = { streets: streets,
                              city: address.city,
                              province: address.state_name,
                              postal: address.zipcode,
                              country: (address.country&.iso3 || ''),
                              contact: @body[:customer] }

      @body[:destination].delete_if { |_k, v| v.nil? }
    end

    def sync_body!
      build_flow_request

      @response = @client.orders.put_by_number(ORGANIZATION, @order.number,
                                               Io::Flow::V0::Models::OrderPutForm.new(@body), @opts).to_hash
    end

    def add_item(line_item)
      variant    = line_item.variant
      price_root = variant.flow_data&.dig('exp', @experience, 'prices')&.[](0) || {}

      # create flow order line item
      { center: FLOW_CENTER,
        number: variant.sku,
        quantity: line_item.quantity,
        price: { amount: price_root['amount'] || variant.price,
                 currency: price_root['currency'] || variant.cost_currency } }
    end

    def write_response_to_order
      return @order.flow_data.delete('order') if !@response || error?

      # update local order
      @order.total = @response[:total]&.[](:amount)
      @order.flow_data.merge!('order' => @response)
    end
  end
end
