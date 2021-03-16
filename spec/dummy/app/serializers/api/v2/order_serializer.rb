# frozen_string_literal: true

module Api
  module V2
    # AMS implementation of the Order rabl serializer
    class OrderSerializer < ActiveModel::Serializer
      has_many :payments

      attributes :id, :number, :item_total, :total, :ship_total, :state,
                 :adjustment_total, :user_id, :created_at, :updated_at, :completed_at,
                 :payment_total, :shipment_state, :payment_state, :email, :special_instructions,
                 :channel, :included_tax_total, :additional_tax_total, :display_included_tax_total,
                 :display_additional_tax_total, :tax_total, :currency, :for_gift, :gift_message,
                 :subscribe, :display_item_total, :total_quantity, :display_total,
                 :is_payment_required, :is_delivery_required, :adjusted_shipment_total,
                 :adjusted_shipment_total_display, :display_tax_total, :paypal_method, :tax_rate,
                 :country, :display_estimated_order_total, :adjustments, :is_shipment_splitted, :taxes_included,
                 :promotions_changed, :included_tax_message, :item_subtotal, :total_discounts

      def adjustments
        object.adjustments.eligible
      end

      def total_quantity
        object.line_items.reduce(0) { |sum, li| sum + li.quantity }
      end

      def is_payment_required
        object.payment_required?
      end

      def is_delivery_required
        object.delivery_required?
      end

      def is_shipment_splitted
        object.split_shipment?
      end

      def tax_rate
        # we don't use the scope .tax from Spree::Amount since the order
        # has the adjustments preloaded
        object.adjustments.select { |a| a.source_type = 'Spree::TaxRate' }
              .reduce(0) { |sum, a| sum + a.amount }
      end

      def country
        @instance_options[:country]
      end

      def display_estimated_order_total
        @instance_options[:estimator].display_estimated_order_total
      end

      def taxes_included
        object.included_tax_total > 0
      end

      def included_tax_message
        current_zone = @instance_options[:region_setting]

        I18n.t("included_tax_#{current_zone.name.to_s.parameterize('_')}", default: I18n.t('included_tax'))
      end

      private

      def user_coordinates
        instance_options[:user_coordinates]
      end

      def user_coordinates_present?
        user_coordinates && user_coordinates[:lat] && user_coordinates[:lng]
      end
    end
  end
end
