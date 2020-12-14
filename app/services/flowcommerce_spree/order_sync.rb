# frozen_string_literal: true

module FlowcommerceSpree
  # represents flow.io order syncing service
  # for easy integration we are currently passing:
  # - flow experience
  # - spree order
  # - current customer, presetnt as  @current_spree_user controller instance variable
  #
  # example:
  #  flow_order = FlowcommerceSpree::OrderSync.new    # init flow-order object
  #    order: Spree::Order.last,
  #    experience: @flow_session.experience
  #    customer: Spree::User.last
  #  flow_order.build_flow_request           # builds json body to be posted to flow.io api
  #  flow_order.synchronize!                 # sends order to flow
  class OrderSync
    FLOW_CENTER = 'default'

    attr_reader :digest, :order, :response

    class << self
      def clear_cache(order)
        return unless order.flow_data['order']

        order.flow_data.delete('order')
        order.update_column :flow_data, order.flow_data.dup
      end
    end

    def initialize(order:)
      raise(ArgumentError, 'Experience not defined or not active') unless order.zone&.flow_io_active_experience?

      @experience = order.flow_experience_key
      @order      = order
      @customer   = order.user
      @items      = []
    end

    # helper method to send complete order from Spree to flow.io
    def synchronize!
      sync_body!
      check_state!
      write_response_in_cache
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
      # if we have erorr with an order, but still using this method
      return [] unless @order.flow_order

      @order.flow_data ||= {}

      delivery_list = @order.flow_order['deliveries'][0]['options']
      delivery_list = delivery_list.map do |opts|
        name         = opts['tier']['name']

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
      @order.line_items.each { |line_item| add_item(line_item) }

      @opts = {}
      @opts[:organization] = FlowcommerceSpree::ORGANIZATION
      @opts[:experience]   = @experience
      @opts[:expand]       = 'experience'

      @body = { items: @items, number: @order.number }

      add_customer if @customer

      # if defined, add selection (delivery options) and delivered_duty from flow_data
      @body[:selections] = [@order.flow_data['selection']] if @order.flow_data['selection']
      @body[:delivered_duty] = @order.flow_data['delivered_duty'] if @order.flow_data['delivered_duty']

      # discount on full order is applied
      if @order.adjustment_total != 0
        @body[:discount] = { amount: @order.adjustment_total,
                             currency: @order.currency }
      end

      # calculate digest body and cache it
      @digest = Digest::SHA1.hexdigest(@opts.to_json + @body.to_json)
    end

    private

    # if customer is defined, add customer info
    # it is possible to have order in Spree without customer info (new guest session)
    def add_customer
      return unless @customer

      address = @customer.ship_address
      # address = nil
      if address
        @body[:customer] = { name: { first: address.firstname,
                                     last: address.lastname },
                             email: @customer.email,
                             number: @customer.flow_number,
                             phone: address.phone }

        streets = []
        streets.push address.address1 unless address.address1.blank?
        streets.push address.address2 unless address.address2.blank?

        @body[:destination] = { streets: streets,
                                city: address.city,
                                province: address.state_name,
                                postal: address.zipcode,
                                country: (address.country.iso3 rescue 'USA'),
                                contact: @body[:customer] }

        @body[:destination].delete_if { |_k, v| v.nil? }
      end

      @body
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
        @response ||= FlowcommerceSpree::Api.run :get, '/:organization/orders/%s' % @body[:number], expand: 'experience'
      else
        # replace when fixed integer error
        # @body[:items].map! { |item| ::Io::Flow::V0::Models::LineItemForm.new(item) }
        # @opts[:experience] = @experience.key
        # order_put_form = ::Io::Flow::V0::Models::OrderPutForm.new(@body)
        # r FlowcommerceSpree.client.orders.put_by_number(FlowcommerceSpree::ORGANIZATION, @order.number, order_put_form, @opts)

        # cache last order/put for debug purposes
        # FlowSettings.set 'flow-order-put-body-%s' % @body[:number], @body.to_json

        @response = FlowcommerceSpree::Api.run :put, "/:organization/orders/#{@body[:number]}", @opts, @body
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
      price_root = variant.flow_data.dig('exp', @experience, 'prices')[0] || {}

      # create flow order line item
      item = { center: FLOW_CENTER,
               number: variant.sku,
               quantity: line_item.quantity,
               price: { amount: price_root['amount'] || variant.cost_price,
                        currency: price_root['currency'] || variant.cost_currency } }

      @items.push item
    end

    # set cache for total order ammount
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
        @order.flow_data['digest'] = @digest
        @order.flow_data['order']  = @response.to_hash
      end

      @order.update_column(:meta, @order.meta.to_json)
    end
  end
end
