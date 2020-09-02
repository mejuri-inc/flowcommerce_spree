module Flow
  class Experience < Settings
    store_accessor :data, :country, :currency, :delivered_duty, :language, :measurement_system,
                   :name, :position, :region, :settings, :status, :subcatalog

    def upsert_data(received_experience)
      exp_hash = received_experience.is_a?(Hash) ? received_experience : received_experience.to_hash

      new_record? ? update_attribute(:data, exp_hash) : update_column(:data, exp_hash.to_json)

      exp_hash
    end
  end
end
