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
  class OrderSync
    FLOW_CENTER = 'default'
    SESSION_EXPIRATION_THRESHOLD = 10 # Refresh session if less than 10 seconds to session expiration remains

    attr_reader :digest, :order, :response

    delegate :url_helpers, to: 'Rails.application.routes'

    class << self
      def clear_cache(order)
        return unless order.flow_data['order']

        order.flow_data.delete('order')
        order.update_column :meta, order.meta.to_json
      end
    end

    def initialize(order:)
      raise(ArgumentError, 'Experience not defined or not active') unless order.zone&.flow_io_active_experience?

      @experience = order.flow_io_experience_key
      @order = order
      @client = FlowcommerceSpree.client(session_id: fetch_session_id)
    end

    # helper method to send complete order from Spree to flow.io
    def synchronize!
      sync_body!
      check_state!
      write_response_in_cache

      # This is for 1st order syncing, when no checkout_token has been fetched yet. In all the subsequent syncs,
      # the checkout_token is fetched in the `fetch_session_id` method, calling the refresh_checkout_token method when
      # necessary.
      refresh_checkout_token if @order.flow_io_checkout_token.blank?
      @order.update_column(:meta, @order.meta.to_json)
      @response
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

    def delivery
      deliveries.select { |el| el[:active] }.first
    end

    # delivery methods are defined in flow console
    def deliveries
      # if we have error with an order, but still using this method
      return [] unless @order.flow_order

      @order.flow_data ||= {}

      delivery_list = @order.flow_order['deliveries'][0]['options']
      delivery_list = delivery_list.map do |opts|
        name = opts['tier']['name']

        # add original Flow ID
        # name        += ' (%s)' % opts['tier']['strategy'] if opts['tier']['strategy']

        selection_id = opts['id']

        { id: selection_id,
          price: { label: opts['price']['label'] },
          active: @order.flow_order['selections'].include?(selection_id),
          name: name }
      end.to_a

      # make first one active unless we have active element
      delivery_list.first[:active] = true unless delivery_list.select { |el| el[:active] }.first

      delivery_list
    end

    def total_price
      @order.flow_total
    end

    def delivered_duty
      # paid is default
      @order.flow_data['delivered_duty'] || ::Io::Flow::V0::Models::DeliveredDuty.paid.value
    end

    # builds object that can be sent to api.flow.io to sync order data
    def build_flow_request
      @opts = { experience: @experience, expand: ['experience'] }
      @body = { items: @order.line_items.map { |line_item| add_item(line_item) } }

      try_to_add_customer

      if (flow_data = @order.flow_data['order'])
        @body[:selections] = flow_data['selections'].presence
        @body[:delivered_duty] = flow_data['delivered_duty'].presence
        @body[:attributes] = flow_data['attributes'].presence

        if @order.adjustment_total != 0
          # discount on full order is applied
          @body[:discount] = { amount: @order.adjustment_total, currency: @order.currency }
        end
      end

      # calculate digest body and cache it
      @digest = Digest::SHA1.hexdigest(@opts.to_json + @body.to_json)
    end

    private

    def fetch_session_id
      session = RequestStore.store[:session]
      current_session_id = session&.[]('_f60_session')
      session_expire_at = session&.[]('_f60_expires_at')&.to_datetime
      order_flow_session_id = @order.flow_data['session_id']
      order_session_expire_at = @order.flow_io_session_expires_at

      if current_session_id && session_expire_at && !flow_io_session_expired?(session_expire_at.to_i)
        # If request flow_session is not expired, don't refresh the flow_session (i.e., don't mark the refresh_session
        # lvar as true), just store the flow_session data into the order, if it is new, and refresh the checkout_token
        refresh_session = nil
      elsif order_flow_session_id && order_session_expire_at && !flow_io_session_expired?(order_session_expire_at.to_i)
        refresh_checkout_token if @order.flow_io_order_id && @order.flow_io_checkout_token.blank?
        return order_flow_session_id
      else
        refresh_session = true
      end

      if order_flow_session_id == current_session_id && session_expire_at == order_session_expire_at &&
        @order.flow_io_checkout_token.present?
        return current_session_id
      end

      if refresh_session
        flow_io_session = Session.new(
          ip: '127.0.0.1',
          visitor: "session-#{Digest::SHA1.hexdigest(@order.guest_token)}",
          experience: @experience
        )
        flow_io_session.create
        current_session_id = flow_io_session.id
        session_expire_at = flow_io_session.expires_at.to_s
      end

      @order.flow_data['session_id'] = current_session_id
      @order.flow_data['session_expires_at'] = session_expire_at

      if session.respond_to?(:[])
        session['_f60_session'] = current_session_id
        session['_f60_expires_at'] = session_expire_at
      end

      # On the 1st OrderSync at this moment the order is not yet created at flow.io, so we couldn't yet retrieve the
      # checkout_token. This is done after the order will be synced, in the `synchronize!` method.
      refresh_checkout_token if @order.flow_io_order_id

      current_session_id
    end

    def flow_io_session_expired?(expiration_time)
      expiration_time - Time.zone.now.utc.to_i < SESSION_EXPIRATION_THRESHOLD
    end

    def refresh_checkout_token
      root_url = url_helpers.root_url
      order_number = @order.number
      checkout_token = FlowcommerceSpree.client.checkout_tokens.post_checkout_and_tokens_by_organization(
        FlowcommerceSpree::ORGANIZATION,
        discriminator: 'checkout_token_reference_form',
        order_number: order_number,
        session_id: @order.flow_data['session_id'],
        urls: { continue_shopping: root_url,
                confirmation: "#{root_url}thankyou?order=#{order_number}&t=#{@order.guest_token}",
                invalid_checkout: root_url }
      )
      @order.add_flow_checkout_token(checkout_token.id)
    end

    # if customer is defined, add customer info
    # it is possible to have order in Spree without customer info (new guest session)
    def try_to_add_customer
      return unless (customer = @order.user)

      address = customer.ship_address || customer.user_profile&.address

      @body[:customer] = { name: { first: address&.firstname,
                                   last: address&.lastname },
                           email: customer.email,
                           number: customer.flow_number,
                           phone: address&.phone }

      streets = []
      streets.push address.address1 unless address&.address1.blank?
      streets.push address.address2 unless address&.address2.blank?

      @body[:destination] = { streets: streets,
                              city: address&.city,
                              province: address&.state_name,
                              postal: address&.zipcode,
                              country: (address&.country&.iso3 || 'USA'),
                              contact: @body[:customer] }

      @body[:destination].delete_if { |_k, v| v.nil? }
    end

    def sync_body!
      build_flow_request if @body.blank?

      @use_get = false

      # use get if order is completed and closed
      @use_get = true if @order.state == 'complete'

      # use get if local digest hash check said there is no change
      @use_get ||= true if @order.flow_data['digest'] == @digest

      # do not use get if there is no local order cache
      @use_get = false unless @order.flow_data['order']

      if @use_get
        @response ||= FlowcommerceSpree::Api.run :get, "/:organization/orders/#{@body[:number]}", expand: 'experience'
      else
        @response = @client.orders.put_by_number(FlowcommerceSpree::ORGANIZATION, @order.number,
                                                 Io::Flow::V0::Models::OrderPutForm.new(@body), @opts).to_hash
      end
    end

    def check_state!
      # authorize if not authorized
      # if !@order.flow_order_authorized?

      # authorize payment on complete, unless authorized
      if @order.state == 'complete' && !@order.flow_order_authorized?
        simple_gateway = Flow::SimpleGateway.new(@order)
        simple_gateway.cc_authorization
      end

      @order.flow_finalize! if @order.flow_order_authorized? && @order.state != 'complete'
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
        @order.flow_data.delete('digest')
        @order.flow_data.delete('order')
      else
        response_total = @response.dig('total', 'label')
        cache_total    = @order.flow_data.dig('order', 'total', 'label')

        # return if total is not changed, no products removed or added
        return if @use_get && response_total == cache_total

        # update local order
        @order.flow_data.merge!('digest' => @digest, 'order' => @response.to_hash)
      end
    end
  end
end
