# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      Order.module_eval do
        # The current incomplete order from the guest_token for use in cart and during checkout
        def current_order(options = {})
          adjust_zone_and_ip && (return @current_order) if @current_order

          @current_order = find_order_by_token_or_user(options)

          if options[:create_order_if_necessary] && (@current_order.nil? || @current_order.completed?)
            @current_order = Spree::Order.new(current_order_params)
            @current_order.user ||= try_spree_current_user
            # See issue #3346 for reasons why this line is here
            @current_order.created_by ||= @current_order.user
            adjust_zone_and_ip
          end

          @current_order
        end

        private

        def adjust_zone_and_ip
          update_meta = @current_order.zone_id ? nil : true
          @current_order.zone = current_zone
          if @current_order.new_record?
            @current_order.last_ip_address = ip_address
            return @current_order.save
          end

          attrs_to_update = { last_ip_address: ip_address }

          # :meta is a jsonb column costly to update every time, especially with all the flow.io data, that's why
          # here it is updated only if there was no zone_id inside :meta
          attrs_to_update[:meta] = @current_order.meta.to_json if update_meta

          @current_order.update_columns(attrs_to_update)
        end

        def find_order_by_token_or_user(options = {})
          options[:lock] ||= false

          # Find any incomplete orders for the token
          incomplete_orders = Spree::Order.incomplete.includes(line_items: [variant: %i[images option_values product]])
          token_order_params = current_order_params.except(:user_id)

          order = incomplete_orders.lock(options[:lock]).find_by(token_order_params)

          # Find any incomplete orders for the current user
          order = last_incomplete_order if order.nil? && try_spree_current_user

          order
        end
      end
    end
  end
end
