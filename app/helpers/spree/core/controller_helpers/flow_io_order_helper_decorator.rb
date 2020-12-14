# frozen_string_literal: true

# Spree::Core::ControllerHelpers::Order decorator to inject Flow.io Experience into the order, if such an Experience
# is present in the Order's zone
module Spree
  module Core
    module ControllerHelpers
      module FlowIoOrderHelperDecorator
        private

        def adjust_zone_and_ip
          @current_order.zone = current_zone
          @current_order.flow_io_experience_from_zone if @current_order.zone&.flow_io_active_experience?
          if @current_order.new_record?
            @current_order.save!
          else
            @current_order.update_columns(last_ip_address: ip_address, meta: @current_order.meta.to_json)
          end
        end

        if ApplicationController.included_modules.exclude?(self)
          ApplicationController.prepend(self)
        end
      end
    end
  end
end
