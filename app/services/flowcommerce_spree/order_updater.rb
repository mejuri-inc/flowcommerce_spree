# frozen_string_literal: true

module FlowcommerceSpree
  class OrderUpdater
    def initialize(order:)
      raise(ArgumentError, 'Experience not defined or not active') unless order&.zone&.flow_io_active_experience?

      @experience = order.flow_io_experience_key
      @order = order
      @client = FlowcommerceSpree.client
    end

    def upsert_data(flow_io_order = nil)
      return if @order.state == 'complete'

      flow_io_order ||= @client.orders.get_by_number(FlowcommerceSpree::ORGANIZATION, @order.number).to_hash

      Rails.logger.info "[!] Flow IO Order data #{flow_io_order}"

      @order.flow_data['order'] = flow_io_order
      return if @order.flow_data.dig('order', 'submitted_at').blank?

      attrs_to_update = { meta: @order.meta.to_json, email: @order.flow_customer_email, payment_state: 'pending' }
      attrs_to_update.merge!(@order.prepare_flow_addresses)
      @order.state = 'delivery'
      @order.save!
      @order.create_proposed_shipments
      @order.shipment.update_amounts
      @order.line_items.each(&:store_ets)

      @order.update_columns(attrs_to_update)
      @order.state = 'payment'
      @order.save!
    end

    def finalize_order
      @order.finalize!
      @order.update_totals
      @order.save
      @order.charge_taxes
      @order.after_completed_order
    end

    def complete_checkout
      upsert_data
      map_payments_to_spree

      finalize_order
    end

    def map_payments_to_spree
      @order.flow_io_payments&.each do |p|
        payment =
          @order.payments.find_or_initialize_by(response_code: p['reference'], payment_method_id: payment_method_id)
        next unless payment.new_record?

        payment.amount = p.dig('total', 'amount')
        if p['type'] == 'card'
          card = Spree::CreditCard.where("user_id = ? AND meta -> 'flow_data' -> 'authorizations' @> ?", @order.user.id,
                                         [{ id: p['reference'] }].to_json).first
          payment.source = card if card
        end
        payment.pend

        # For now this additional update is overwriting the generated identifier with flow.io payment identifier.
        # TODO: Check and possibly refactor in Spree 3.0, where the `before_create :set_unique_identifier`
        # has been removed.
        payment.update_column(:identifier, p['id'])
      end

      return if @order.payments.sum(:amount) < @order.amount || @order.state == 'complete'

      @order.state = 'complete'
      @order.save!
    end
  end
end
