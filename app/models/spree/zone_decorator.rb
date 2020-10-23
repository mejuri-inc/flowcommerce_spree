module Spree
  Zone.class_eval do
    store_accessor :options, :flow_data

    def import_flowcommerce(received_experience)
      self.flow_data = received_experience.is_a?(Hash) ? received_experience : received_experience.to_hash

      self.status = flow_data['status']
      if new_record?
        update_attributes(options: options, status: status)
      else
        update_columns(options: options.to_json, status: status)
      end
    end
  end
end
