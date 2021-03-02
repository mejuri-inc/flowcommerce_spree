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
            order_flow_session_id = @current_order.flow_data['session_id']
            order_session_expired = @current_order.flow_data['session_expires_at']
            flow_io_session_id = session['_f60_session']
            flow_io_session_expires = session['_f60_expires_at']
            if flow_io_session_id.present?
              if order_flow_session_id != flow_io_session_id &&
                 order_session_expired&.to_datetime.to_i < flow_io_session_expires&.to_datetime.to_i
                @current_order.flow_data['session_id'] = flow_io_session_id
                @current_order.flow_data['session_expires_at'] = flow_io_session_expires
                @current_order.flow_data['checkout_token'] = nil
                update_meta ||= true
              end
            elsif order_flow_session_id.present?
              session['_f60_session'] = order_flow_session_id
              session['_f60_expires_at'] = order_session_expired
            end
            cookies['_f60_session'] = order_flow_session_id
          end

          if @current_order.new_record?
            @current_order.last_ip_address = ip_address
            return @current_order.save
          end

          attrs_to_update = {}

          # Update last_ip_address only for a new request_id
          attrs_to_update = { last_ip_address: ip_address } if @request_id != request_id

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
