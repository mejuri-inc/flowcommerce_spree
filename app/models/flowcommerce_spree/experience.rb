module FlowcommerceSpree
  class Experience < Settings
    store_accessor :data, :country, :currency, :delivered_duty, :language, :measurement_system,
                   :name, :position, :region, :settings, :status, :subcatalog

    validates_inclusion_of :country, in: Spree::Country.all.pluck(:iso3)

    def upsert_data(received_experience)
      self.data = received_experience.is_a?(Hash) ? received_experience : received_experience.to_hash
      return { error: 'ExperienceValidationError', message: errors.messages } unless valid?

      new_record? ? update_attribute(:data, data) : update_column(:data, data.to_json)

      if (experience_associator = FlowcommerceSpree.experience_associator)
        result = experience_associator.run(self)
        return result if result[:error]
      end

      data
    end
  end
end
