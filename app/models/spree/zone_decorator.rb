module Spree
  Zone.class_eval do
    store_accessor :options, :flow_data

    after_initialize :redefine_available_currencies

    def redefine_available_currencies
      return if self.class.method_defined?(:available_currencies_redefined_by_flow?)

      old_available_currencies = self.class.instance_method(:available_currencies)

      self.class.__send__(:define_method, :available_currencies) do
        (old_available_currencies.bind(self).() + [flow_data&.[]('currency')]).compact.uniq
      end

      self.class.__send__(:define_method, :available_currencies_redefined_by_flow?) do
        true
      end
    end

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
