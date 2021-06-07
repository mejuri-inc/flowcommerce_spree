# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::ImportItemWorker, type: :worker do
  subject(:job) { described_class.new }

  context 'when variant exists' do
    let(:variant) { create(:base_variant, :with_flow_data) }

    it 'calls ImportItem service' do
      expect(FlowcommerceSpree::ImportItem).to(receive(:run).once)

      job.perform(variant.sku)
    end
  end

  context 'when variant does not exists' do
    it 'does not call ImportItem service' do
      expect(FlowcommerceSpree::ImportItem).not_to(receive(:run))

      job.perform('doesnotexists')
    end
  end
end
