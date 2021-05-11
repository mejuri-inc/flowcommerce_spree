# frozen_string_literal: true

module Spree
  # Added flow specific methods to Spree::Order
  module FlowIoOrderDecorator
    def self.included(base)
      base.serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

      base.store_accessor :meta, :flow_data
    end

    def flow_tax_cache_key
      [number, 'flowcommerce', 'allocation', line_items.sum(:quantity)].join('-')
    end

    def display_total
      return unless flow_data&.[]('order')

      Spree::Money.new(flow_io_total_amount, currency: currency)
    end

    def flow_order
      flow_data&.[]('order')
    end

    def flow_order_with_payments?
      payment = payments.completed.first

      payment&.payment_method&.type == 'Spree::Gateway::FlowIo'
    end

    # accepts line item, usually called from views
    def flow_line_item_price(line_item, total = false)
      result = if (order = flow_order)
                 item = order['lines']&.find { |el| el['item_number'] == line_item.variant.sku }

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

    # shows localized total, if possible. if not, fall back to Spree default
    def flow_io_total_amount
      flow_data&.dig('order', 'total', 'amount')&.to_d || 0
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

    def flow_io_attributes
      flow_data&.dig('order', 'attributes') || {}
    end

    def flow_io_attribute_add(attr_key, value)
      self.flow_data['order'] ||= {}
      self.flow_data['order']['attributes'] ||= {}
      self.flow_data['order']['attributes'][attr_key] = value
    end

    def add_user_uuid_to_flow_data
      self.flow_data['order'] ||= {}
      self.flow_data['order']['attributes'] ||= {}
      self.flow_data['order']['attributes']['user_uuid'] = user&.uuid || ''
    end

    def flow_io_attr_user_uuid
      flow_data&.dig('order', 'attributes', 'user_uuid')
    end

    def flow_io_captures
      flow_data&.[]('captures')
    end

    def flow_io_captures_sum
      captures_sum = 0
      flow_data&.[]('captures')&.each do |c|
        next if c['status'] != 'succeeded'

        amount = c['amount']
        amount = amount.to_d if amount.is_a?(String)
        captures_sum += amount
      end
      captures_sum.to_d
    end

    def flow_io_balance_amount
      flow_data&.dig('order', 'balance', 'amount')&.to_d || 0
    end

    def flow_io_payments
      flow_data.dig('order', 'payments')
    end

    def flow_customer_email
      flow_data.dig('order', 'customer', 'email')
    end

    def flow_ship_address
      flow_destination = flow_data.dig('order', 'destination')
      return unless flow_destination.present?

      flow_destination['first'] = flow_destination.dig('contact', 'name', 'first')
      flow_destination['last']  = flow_destination.dig('contact', 'name', 'last')
      flow_destination['phone'] = flow_destination.dig('contact', 'phone')

      s_address = ship_address || build_ship_address
      s_address.prepare_from_flow_attributes(flow_destination)
      s_address
    end

    def flow_bill_address
      flow_payment_address = flow_data.dig('order', 'payments')&.last&.[]('address')
      return unless flow_payment_address

      flow_payment_address['first'] = flow_payment_address.dig('name', 'first')
      flow_payment_address['last']  = flow_payment_address.dig('name', 'last')
      flow_payment_address['phone'] = ship_address['phone']

      b_address = bill_address || build_bill_address
      b_address.prepare_from_flow_attributes(flow_payment_address)
      b_address
    end

    def prepare_flow_addresses
      address_attributes = {}

      s_address = flow_ship_address

      if s_address&.changes&.any?
        s_address.save!
        address_attributes[:ship_address_id] = s_address.id unless ship_address_id
      end

      b_address = flow_bill_address
      if b_address&.changes&.any?
        b_address.save!
        address_attributes[:bill_address_id] = b_address.id unless bill_address_id
      end

      address_attributes
    end

    def flow_allocations
      return @flow_allocations if @flow_allocations

      @flow_allocations = flow_order&.[]('allocations')
    end

    def flow_tax_for_item(item, tax_key, included_in_price = true)
      return {} if flow_allocations.blank?

      item_details = flow_allocations['details']&.find do |el|
        item.is_a?(Spree::LineItem) ? el['number'] == item.variant.sku : el['key'] == 'shipping'
      end
      price_components = included_in_price ? item_details['included'] : item_details['not_included']
      price_components&.find { |el| el['key'] == tax_key }
    end

    Spree::Order.include(self) if Spree::Order.included_modules.exclude?(self)
  end
end
