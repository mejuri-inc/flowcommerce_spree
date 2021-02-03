# frozen_string_literal: true

module Spree # rubocop:disable Metrics/ModuleLength
  ZONE_STATUSES = %w[active archived archiving draft inactive updating].freeze

  Zone.class_eval do
    self.inheritance_column = :klass

    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :currencies, :collection_ids, :sku_suffix, :taxon_ids

    # TODO: Remove countries and states on upgrade from Spree 3.0 from where is copied
    has_many :countries, through: :zone_members, source: :zoneable, source_type: 'Spree::Country'
    has_many :states, through: :zone_members, source: :zoneable, source_type: 'Spree::State'
    has_many :zipcode_ranges, through: :zone_members, source: :zoneable, source_type: 'ZipcodeRange'

    # Find the :name uniqueness validation callback filter defined in the original Spree::Zone to then remove it and
    # replace with a similar one, but scoped by Zone's :klass
    unique_name_filter = _validate_callbacks.find do |c|
      c.filter.is_a?(ActiveRecord::Validations::UniquenessValidator) &&
        c.filter.instance_variable_get(:@attributes) == [:name]
    end.filter

    skip_callback(:validate, unique_name_filter)

    validates :name, uniqueness: { scope: :klass }
    validate :klass, :klass_was_not_set, if: -> { klass_changed? }
    validates :status, inclusion: { in: Spree::ZONE_STATUSES }

    validates_absence_of :collection_ids, :sku_suffix, :taxon_ids,
                         unless: ->(zone) { zone.klass == 'Spree::Zones::Product' }

    validates_each :sku_suffix, if: ->(zone) { zone.klass == 'Spree::Zones::Product' } do |record, attr, value|
      next if value.blank?

      if Spree::Zones::Product
         .where("meta->>'sku_suffix' = ?", value).exists? && record.meta_was['sku_suffix'] != value
        record.errors.add(attr, 'sku_suffix should be unique')
      end
    end

    scope :active, -> { where(status: 'active') }

    ransacker(:sku_suffix) { |parent| Arel::Nodes::InfixOperation.new('->>', parent.table[:meta], 'sku_suffix') }

    self.whitelisted_ransackable_attributes |= %w[klass sku_suffix status]

    # TODO: Remove on upgrade from Spree 3.0 from where is copied
    def self.potential_matching_zones(zone)
      if zone.country?
        # Match zones of the same kind with similar countries
        joins(countries: :zones).where('zone_members_spree_countries_join.zone_id = ? OR ' \
                                       'spree_zones.default_tax = ?', zone.id, true).uniq
      else
        # Match zones of the same kind with similar states in AND match zones
        # that have the states countries in
        joins(:zone_members).where("(spree_zone_members.zoneable_type = 'Spree::State' AND " \
                                   'spree_zone_members.zoneable_id IN (?)) ' \
                                   "OR (spree_zone_members.zoneable_type = 'Spree::Country' AND " \
                                   'spree_zone_members.zoneable_id IN (?)) OR default_tax = ? ',
                                   zone.state_ids, zone.states.pluck(:country_id), true).uniq
      end
    end

    # TODO: Should be refactored in the future to be simpler to fetch the zones, without having to check for klass.
    # Returns the matching zone with the highest priority zone type (State, Country, Zone.)
    # Returns nil in the case of no matches.
    def self.match(address)
      return unless address

      matches =
        includes(:zone_members)
        .order('spree_zones.zone_members_count', 'spree_zones.created_at')
        .where("spree_zones.klass = '' OR spree_zones.klass IS NULL")
        .where("(spree_zone_members.zoneable_type = 'Spree::Country' AND spree_zone_members.zoneable_id = ?) OR" \
               "(spree_zone_members.zoneable_type = 'Spree::State' AND spree_zone_members.zoneable_id = ?)",
               address.country_id, address.state_id)
        .references(:zones)
      return unless matches

      match = nil
      %w[state country].each { |zone_kind| break if (match = matches.detect { |zone| zone_kind == zone.kind }) }

      match || matches.first
    end

    def available_currencies
      (currencies || []).compact.uniq.reject(&:empty?)
    end

    # TODO: Remove on upgrade from Spree 3.0 from where is copied
    def kind
      if kind?
        super
      else
        not_nil_scope = members.where.not(zoneable_type: nil)
        zone_type = not_nil_scope.order('created_at ASC').pluck(:zoneable_type).last
        zone_type&.demodulize&.underscore
      end
    end

    # TODO: Remove on upgrade from Spree 3.0 - it is removed there too
    def kind=(value)
      super
    end

    # TODO: Remove on upgrade from Spree 3.0 from where is copied
    def country?
      kind == 'country'
    end

    # TODO: Remove on upgrade from Spree 3.0 from where is copied
    def state?
      kind == 'state'
    end

    def zipcode_range?
      kind == 'zipcode_range'
    end

    def include?(address)
      return false if address.blank?

      if country?
        members.find_by(zoneable_id: address.country_id).present?
      elsif state?
        members.find_by(zoneable_id: address.state_id).present?
      elsif zipcode_range?
        ZipcodeRange.included(address, members)
      else
        false
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def contains?(target)
      return false if zipcode_range? || target.zipcode_range?
      return false if state? && target.country?
      return false if zone_members.empty? || target.zone_members.empty?

      countries_ids = countries.pluck(:id)

      if kind == target.kind
        if state?
          return false if (target.states.pluck(:id) - states.pluck(:id)).present?
        elsif country?
          return false if (target.countries.pluck(:id) - countries_ids).present?
        elsif zipcode_range?
          return false if (target.zipcode_ranges.pluck(:id) - zipcode_ranges.pluck(:id)).present?
        end
      else
        return false if (target.states.pluck(:country_id) - countries_ids).present?
        return false if (target.zipcode_ranges.pluck(:country_id) - countries_ids).present?
      end
      true
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    # All zoneables belonging to the zone members.  Will be a collection of either
    # countries or states depending on the zone type.
    def zoneables
      zipcode_range? ? [] : members.includes(:zoneable).collect(&:zoneable)
    end

    def zipcode_range_ids
      kind == 'zipcode' ? members.pluck(:zoneable_id) : []
    end

    def zipcode_ids=(ids)
      set_zone_members(ids, 'ZipcodeRange')
    end

    private

    def set_zone_members(ids, type)
      zone_members.destroy_all
      ids.reject(&:blank?).map do |id|
        member = Spree::ZoneMember.new
        member.zoneable_type = type
        member.zoneable_id = id
        member.zone_type = klass
        members << member
      end
    end

    def remove_defunct_members
      return if zone_members.empty?

      kind_classified = kind.classify
      class_name = kind == 'zipcode_range' ? kind_classified : "Spree::#{kind_classified}"
      zone_members.where('zoneable_id IS NULL OR zoneable_type != ?', class_name).destroy_all
    end

    def klass_was_not_set
      errors.add(:klass, 'can only be changed if it was blank') if changed_attributes[:klass].present?
    end

    # TODO: Remove on upgrade from Spree 3.1 from where is copied
    def remove_previous_default
      return unless default_tax && default_tax_changed?

      Spree::Zone.where(default_tax: true).where('id != ?', id).update_all(default_tax: false)
    end
  end
end
