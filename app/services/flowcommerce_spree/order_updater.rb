# frozen_string_literal: true

module FlowcommerceSpree
  class OrderUpdater
    def initialize(order:)
      raise(ArgumentError, 'Experience not defined or not active') unless order.zone&.flow_io_active_experience?

      @experience = order.flow_io_experience_key
      @order = order
      @client = FlowcommerceSpree.client
    end

    def upsert_data(flow_io_order = nil)
      flow_io_order ||= @client.orders.get_by_number(FlowcommerceSpree::ORGANIZATION, @order.number).to_hash

      Rails.logger.info "[!] Flow IO Order data #{flow_io_order}"

      @order.flow_data['order'] = flow_io_order
      attrs_to_update = { meta: @order.meta.to_json }
      if @order.flow_data.dig('order', 'submitted_at').present? && !@order.complete?
        attrs_to_update[:email] = @order.flow_customer_email
        attrs_to_update[:payment_state] = 'pending'
        attrs_to_update.merge!(@order.prepare_flow_addresses)
        # @order.state = 'delivery'
        # @order.save!
        @order.create_proposed_shipments
        @order.shipment.update_amounts
        @order.line_items.each(&:store_ets)

        # TODO : Add payment mapping
      end

      @order.update_columns(attrs_to_update)
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

      @order.state = 'complete'
      @order.save!

      finalize_order
    end
  end
end
