# frozen_string_literal: true

module FlowcommerceSpree
  module Webhooks
    class CardAuthorizationUpsertedV2
      attr_accessor :errors
      alias full_messages errors

      def self.process(data, opts = {})
        new(data, opts).process
      end

      def initialize(data, opts = {})
        @card_auth = data['authorization']&.to_hash
        @card_auth['method'].delete('images')
        @opts = opts
        @errors = []
      end

      def process
        errors << { message: 'Authorization param missing' } && (return self) unless @card_auth

        errors << { message: 'Card param missing' } && (return self) unless (flow_io_card = @card_auth.delete('card'))

        if (order_number = @card_auth.dig('order', 'number'))
          if (order = Spree::Order.find_by(number: order_number))
            card = upsert_card(flow_io_card, order)

            order.payments.where(response_code: @card_auth['id'])
                 .update_all(source_id: card.id, source_type: 'Spree::CreditCard')

            return card
          else
            errors << { message: "Order #{order_number} not found" }
          end
        else
          errors << { message: 'Order number param missing' }
        end

        self
      end

      private

      def upsert_card(flow_io_card, order)
        flow_io_card_expiration = flow_io_card.delete('expiration')

        card = Spree::CreditCard.find_or_initialize_by(month: flow_io_card_expiration['month'].to_s,
                                                       year: flow_io_card_expiration['year'].to_s,
                                                       cc_type: flow_io_card.delete('type'),
                                                       last_digits: flow_io_card.delete('last4'),
                                                       name: flow_io_card.delete('name'),
                                                       user_id: order.user&.id)
        card.flow_data ||= {}
        if card.new_record?
          card.flow_data.merge!(flow_io_card.except('discriminator'))
          card.imported = true
        end

        card.push_authorization(@card_auth.except('discriminator'))
        card.new_record? ? card.save : card.update_column(:meta, card.meta.to_json)

        card
      end
    end
  end
end
