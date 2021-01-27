# frozen_string_literal: true

module Spree
  Order.class_eval do

    store_accessor :meta, :zone_id

    def zone
      @zone ||= zone_id ? Spree::Zones::Product.find_by(id: zone_id) : nil
    end

    def zone=(zone)
      self.zone_id ||= zone.id

      # rubocop:disable Naming/MemoizedInstanceVariableName
      @zone ||= zone.id == zone_id ? zone : Spree::Zones::Product.find_by(id: zone_id)
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
