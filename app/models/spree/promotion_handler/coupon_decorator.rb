# frozen_string_literal: true

module Spree
  module PromotionHandler
    Coupon.class_eval do
      def apply
        if order.coupon_code.present?
          if promotion&.actions.exists?
            experience_key  = order.flow_order.dig('experience', 'key')
            forbiden_keys   = promotion.flow_data.dig('filter', 'experience') || []

            if experience_key.present? && !forbiden_keys.include?(experience_key)
              self.error = 'Promotion is not available in current country'
            else
              handle_present_promotion(promotion)
            end
          else
            self.error = if Promotion.with_coupon_code(order.coupon_code)&.expired?
                           Spree.t(:coupon_code_expired)
                         else
                           Spree.t(:coupon_code_not_found)
                         end
          end
        end

        self
      end
    end
  end
end
