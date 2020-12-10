# Flow (2017)
# `:display_total` modifications to display total prices beside Spree default. Example: https://i.imgur.com/7v2ix2G.png
# Added flow specific methods to Spree::Order
module Spree
  Order.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :flow_data

    state_machine.before_transition from: :cart, do: :sync_to_flow_io_if_needed

    def sync_to_flow_io_if_needed
      return unless zone&.flow_active_experience?
    end

    def display_total
      price = Flow.format_default_price total
      price += ' (%s)' % flow_total if flow_order
      price.html_safe
    end

    # we now use Spree number as Flow number, but I will leave this here for now
    def flow_number
      return self[:flow_number] unless self[:flow_number].blank?

      return unless id

      number
    end

    def flow_order
      return nil unless flow_data['order']

      Hashie::Mash.new flow_data['order']
    end

    # accepts line item, usually called from views
    def flow_line_item_price(line_item, total = false)
      result = if flow_order
                 id = line_item.variant.id.to_s

                 lines = flow_order.lines || []
                 item  = lines.select { |el| el['item_number'] == id }.first

                 return Flow.price_not_found unless item

                 total ? item['total']['label'] : item['price']['label']
               else
                 Flow.format_default_price(line_item.price * (total ? line_item.quantity : 1))
               end

      # add line item promo
      # promo_total, adjustment_total
      result += ' (%s)' % Flow.format_default_price(line_item.promo_total) if line_item.promo_total > 0

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
          raise Flow::Error.new(message)
        end

        flow_order.prices.each do |price|
          prices.push price_model.new(price['name'], price['label'])
        end
      else
        price_elements = [:item_total, :adjustment_total, :included_tax_total, :additional_tax_total, :tax_total, :shipment_total, :promo_total]
        price_elements.each do |el|
          price = send(el)
          if price > 0
            label = Flow.format_default_price price
            prices.push price_model.new(el.to_s.humanize.capitalize, label)
          end
        end

        # discount is applied and we allways show it in default currency
        if adjustment_total != 0
          formated_discounted_price = Flow.format_default_price adjustment_total
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
      price || Flow.format_default_price(total)
    end

    def flow_experience
      model = Struct.new(:key)
      model.new flow_order.experience.key
    rescue
      model.new ENV.fetch('FLOW_BASE_COUNTRY')
    end

    # clear invalid zero amount payments. Solidsus bug?
    def clear_zero_amount_payments!
      # class attribute that can be set to true
      return unless Flow::Order.clear_zero_amount_payments

      payments.where(amount:0, state: ['invalid', 'processing', 'pending']).map(&:destroy)
    end

    def flow_order_authorized?
      flow_data && flow_data['authorization'] ? true : false
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
