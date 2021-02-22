# frozen_string_literal: true

module Tracking
  Setup.module_eval do
    private

    def setup_tracking
      return if request.path.start_with?(ADMIN_PATH)

      user_consents = UserConsent.new(cookies)
      setup_visitor_cookie(user_consents)
      store_order_flow_io_attributes(user_consents) if current_order&.zone&.flow_io_active_experience?
    end

    def store_order_flow_io_attributes(user_consents)
      # Using `save!` and not `update_column` for callbacks to work and sync the order to flow.io
      current_order.save!(validate: false) if order_user_consents_updated?(user_consents) || user_uuid_updated?
    end

    def order_user_consents_updated?(user_consents)
      consents_changed = nil
      user_consents.active_groups.each do |consent_group|
        group_value = consent_group[1][:value]
        gdpr_group_name = "gdpr_#{consent_group[1][:name]}"
        next if current_order.flow_io_attributes[gdpr_group_name] == group_value

        consents_changed ||= true
        current_order.flow_io_attribute_add(gdpr_group_name, group_value)
      end

      consents_changed
    end

    def user_uuid_updated?
      return if current_order.flow_io_attr_user_uuid.present?

      current_order.add_user_uuid_to_flow_data
    end
  end
end
