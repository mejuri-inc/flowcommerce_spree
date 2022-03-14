# frozen_string_literal: true

module FlowcommerceSpree
  class OrderUpdater
    def initialize(order:)
      unless order&.zone&.flow_io_active_or_archiving_experience?
        raise(ArgumentError, 'Experience not defined or not active')
      end

      @experience = order.flow_io_experience_key
      @order = order
      @client = FlowcommerceSpree.client
    end

    def upsert_data(flow_io_order = nil)
      return if @order.state == 'complete'

      flow_io_order ||= @client.orders.get_by_number(FlowcommerceSpree::ORGANIZATION, @order.number).to_hash

      @order.flow_data['order'] = flow_io_order
      return if @order.flow_data.dig('order', 'submitted_at').blank?

      attrs_to_update = { meta: @order.meta.to_json, email: @order.flow_customer_email, payment_state: 'pending' }
      attrs_to_update.merge!(@order.prepare_flow_addresses)
      @order.update_columns(attrs_to_update)
      @order.state = 'delivery'
      @order.save!
      @order.create_proposed_shipments
      @order.shipment.update_amounts
      @order.line_items.each(&:store_ets)
      @order.charge_taxes

      @order.state = 'payment'
      @order.save!
    end

    def finalize_order
      @order.reload
      @order.finalize!
      @order.update_totals
      @order.save
      @order.after_completed_order
    end

    def complete_checkout
      upsert_data
      map_payments_to_spree
      finalize_order if @order.state == 'complete'
    end

    def map_payments_to_spree
      @order.flow_io_payments&.each do |p|
        payment =
          @order.payments.find_or_initialize_by(response_code: p['reference'], payment_method_id: payment_method_id)
        next unless payment.new_record?

        payment.amount = p.dig('total', 'amount')
        payment.pend

        # For now this additional update is overwriting the generated identifier with flow.io payment identifier.
        # TODO: Check and possibly refactor in Spree 3.0, where the `before_create :set_unique_identifier`
        # has been removed.
        payment.update_column(:identifier, p['id'])
      end

      if @order.payments.blank?
        payment_method = Spree::PaymentMethod.find_by type: 'Spree::Gateway::FlowIo'
        placeholder_payment = Spree::Payment.new(amount: @order.flow_io_total_amount, order: @order,
          source: nil, payment_method_id: payment_method.id, state: 'pending')
        @order.payments << placeholder_payment
        @order.save
      end

      return if @order.completed?
      return if @order.payments.sum(:amount) < @order.flow_io_total_amount

      @order.state = 'confirm'
      @order.save!
      @order.state = 'complete'
      @order.save!
    end

    def payment_method_id
      @payment_method_id ||= Spree::PaymentMethod.find_by(active: true, type: 'Spree::Gateway::FlowIo').id
    end
  end
end
