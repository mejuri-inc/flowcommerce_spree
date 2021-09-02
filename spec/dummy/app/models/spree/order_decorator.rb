# frozen_string_literal: true

module Spree
  Order.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true) unless serialized_attributes['meta']

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

    def locale_path; end

    def shipment
      shipments.first
    end

    def charge_taxes
      create_tax_charge!
      persist_totals
      audit_taxes
    end

    def audit_taxes
      all_adjustments.tax.each { |adjustment| TaxAudit.audit(adjustment) }
    end

    def after_completed_order; end
  end
end
