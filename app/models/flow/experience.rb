module Flow
  class Experience < Settings
    store_accessor :data, :country, :currency, :delivered_duty, :digest, :discriminator, :language, :measurement_system,
                   :name, :position, :region, :settings, :status, :subcatalog

    def upsert_data(received_experience)
      flow_exp_digest = Digest::SHA1.hexdigest(received_experience.to_json)
      return update_attribute(:data, received_experience.to_hash.merge!(digest: flow_exp_digest)) if new_record?

      update_column(:data, received_experience.to_hash.merge!(digest: flow_exp_digest)) if flow_exp_digest != digest
    end
  end
end
