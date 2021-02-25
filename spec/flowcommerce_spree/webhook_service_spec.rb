# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::WebhookService do
  let(:order) { create(:order_with_line_items, :with_flow_data) }

  describe '#process' do
    context 'when hook does not exists' do
      it 'returns error message' do
        discriminator = 'test_hook'
        webhook_service = FlowcommerceSpree::WebhookService.new('discriminator' => discriminator)

        response = webhook_service.process
        expect(response.errors).to(eq([{ message: "No hook for #{discriminator}" }]))
      end
    end
  end
end
