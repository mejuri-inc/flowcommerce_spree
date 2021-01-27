# frozen_string_literal: true

# `:display_total` modifications to display total prices beside Spree default. Example: https://i.imgur.com/7v2ix2G.png
module Spree # rubocop:disable Metrics/ModuleLength
  # Added flow specific methods to Spree::Order
  Order.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :flow_data

    before_save :sync_to_flow_io
    after_touch :sync_to_flow_io

    def flow_tax_cache_key
      [number, 'flowcommerce', 'allocation', line_items.sum(:quantity)].join('-')
    end

    def sync_to_flow_io
      return unless zone&.flow_io_active_experience? && state == 'cart' && line_items.size > 0

      flow_io_order = FlowcommerceSpree::OrderSync.new(order: self)
      flow_io_order.build_flow_request
      flow_io_order.synchronize! if flow_data['digest'] != flow_io_order.digest
    end

    def display_total
      price = FlowcommerceSpree::Api.format_default_price total
      price += " (#{flow_total})" if flow_order
      price.html_safe
    end

    def flow_order
      return unless flow_data&.[]('order')

      Hashie::Mash.new flow_data['order']
    end

    # accepts line item, usually called from views
    def flow_line_item_price(line_item, total = false)
      result = if flow_order
                 item = flow_order.lines&.find { |el| el['item_number'] == line_item.variant.sku }

                 return 'n/a' unless item

                 total ? item['total']['label'] : item['price']['label']
               else
                 FlowcommerceSpree::Api.format_default_price(line_item.price * (total ? line_item.quantity : 1))
               end

      # add line item promo
      # promo_total, adjustment_total
      result += " (#{FlowcommerceSpree::Api.format_default_price(line_item.promo_total)})" if line_item.promo_total > 0

      result
    end

    # prepares array of prices that can be easily renderd in templates
    def flow_cart_breakdown
      prices = []

      price_model = Struct.new(:name, :label)

      if flow_order
        # duty, vat, ...
        unless flow_order.prices
          message = Flow::Error.format_order_message flow_order
          raise Flow::Error, message
        end

        flow_order.prices.each do |price|
          prices.push price_model.new(price['name'], price['label'])
        end
      else
        price_elements =
          %i[item_total adjustment_total included_tax_total additional_tax_total tax_total shipment_total promo_total]
        price_elements.each do |el|
          price = send(el)
          if price > 0
            label = FlowcommerceSpree::Api.format_default_price price
            prices.push price_model.new(el.to_s.humanize.capitalize, label)
          end
        end

        # discount is applied and we allways show it in default currency
        if adjustment_total != 0
          formated_discounted_price = FlowcommerceSpree::Api.format_default_price adjustment_total
          prices.push price_model.new('Discount', formated_discounted_price)
        end
      end

      # total
      prices.push price_model.new(Spree.t(:total), flow_total)

      prices
    end

    # shows localized total, if possible. if not, fall back to Spree default
    def flow_total
      # r flow_order.total.label
      price = flow_order&.total&.label
      price || FlowcommerceSpree::Api.format_default_price(total)
    end

    def flow_experience
      model = Struct.new(:key)
      model.new flow_order.experience.key
    rescue StandardError => _e
      model.new ENV.fetch('FLOW_BASE_COUNTRY')
    end

    def flow_io_checkout_token
      flow_data&.[]('checkout_token')
    end

    def flow_io_experience_key
      flow_data&.[]('exp')
    end

    def flow_io_experience_from_zone
      self.flow_data = (flow_data || {}).merge!('exp' => zone.flow_io_experience)
    end

    def flow_io_order_id
      flow_data&.dig('order', 'id')
    end

    def flow_io_session_expires_at
      flow_data&.[]('session_expires_at')&.to_datetime
    end

    def flow_io_attributes
      flow_data&.dig('order', 'attributes') || {}
    end

    def add_flow_checkout_token(token)
      self.flow_data ||= {}
      self.flow_data['checkout_token'] = token
    end

    def add_user_consent_to_flow_data(consent, value)
      self.flow_data['order'] ||= {}
      self.flow_data['order']['attributes'] ||= {}
      self.flow_data['order']['attributes'][consent] = value
    end

    def add_user_uuid_to_flow_data
      self.flow_data['order'] ||= {}
      self.flow_data['order']['attributes'] ||= {}
      self.flow_data['order']['attributes']['user_uuid'] = user&.uuid || ''
    end

    def flow_io_attr_user_uuid
      flow_data&.dig('order', 'attributes', 'user_uuid')
    end

    def checkout_url
      checkout_token = flow_io_checkout_token
      return "https://checkout.flow.io/tokens/#{checkout_token}" if checkout_token
    end

    # clear invalid zero amount payments. Solidus bug?
    def clear_zero_amount_payments!
      # class attribute that can be set to true
      return unless Flow::Order.clear_zero_amount_payments

      payments.where(amount: 0, state: %w[invalid processing pending]).map(&:destroy)
    end

    def flow_order_authorized?
      flow_data&.[]('authorization') ? true : false
    end

    def flow_order_captured?
      flow_data['capture'] ? true : false
    end

    # completes order and sets all states to finalized and complete
    # used when we have confirmed capture from Flow API or PayPal
    def flow_finalize!
      finalize! unless state == 'complete'
      update_column :payment_state, 'paid' if payment_state != 'paid'
      update_column :state, 'complete'     if state != 'complete'
    end

    def flow_payment_method
      if flow_data['payment_type'] == 'paypal'
        'paypal'
      else
        'cc' # creait card is default
      end
    end
  end
end
