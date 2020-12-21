# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      # Spree::Core::ControllerHelpers::Order decorator to inject Flow.io Experience into the order, if such an
      # Experience is present in the Order's zone
      module FlowIoOrderHelperDecorator
        private

        def adjust_zone_and_ip
          attrs_to_update = { last_ip_address: ip_address }
          update_meta = @current_order.zone_id ? nil : true
          @current_order.zone = current_zone

          if @current_order.zone&.flow_io_active_experience? && @current_order.flow_io_experience_key.nil?
            @current_order.flow_io_experience_from_zone
            update_meta = true
          end

          return @current_order.save if @current_order.new_record?

          # :meta is a jsonb column costly to update every time, especially with all the flow.io data, that's why
          # here it is updated only if no zone_id there was inside :meta
          attrs_to_update[:meta] = @current_order.meta.to_json if update_meta

          @current_order.update_columns(attrs_to_update)
        end

        if ApplicationController.included_modules.exclude?(self)
          ApplicationController.prepend(self)
        end
      end
    end
  end
end
