# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      # Spree::Core::ControllerHelpers::Order decorator to inject Flow.io Experience into the order, if such an
      # Experience is present in the Order's zone
      module FlowIoOrderHelperDecorator
        private

        def adjust_zone_and_ip
          update_meta = @current_order.zone_id ? nil : true
          @current_order.zone = current_zone

          if @current_order.zone&.flow_io_active_experience?
            if @current_order.flow_io_experience_key.nil?
              @current_order.flow_io_experience_from_zone
              update_meta ||= true
            end
          end

          if @current_order.new_record?
            @current_order.last_ip_address = ip_address
            return @current_order.save
          end

          attrs_to_update = {}

          # Update last_ip_address only when last_ip_address is different.
          attrs_to_update = { last_ip_address: ip_address } if @current_order.last_ip_address != ip_address

          # :meta is a jsonb column costly to update every time, especially with all the flow.io data, that's why
          # here it is updated only if no zone_id there was inside :meta
          attrs_to_update[:meta] = @current_order.meta.to_json if update_meta

          @current_order.update_columns(attrs_to_update) if attrs_to_update.present?
          attrs_to_update
        end

        def request_id
          @request_id ||= env['action_dispatch.request_id']
        end

        ApplicationController.prepend(self) if ApplicationController.included_modules.exclude?(self)
      end
    end
  end
end
