# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::ImportItem do
  subject { FlowcommerceSpree::ImportItem }
  let(:variant) { create(:base_variant) }

  before(:each) do
    allow(FlowcommerceSpree::ImportItem).to(receive(:run).and_call_original)
  end

  context 'when there are no active experiences' do
    before(:each) do
      allow_any_instance_of(Io::Flow::V0::Clients::Experiences).to(receive(:get).and_return([]))
    end

    it 'won`t fetch variant information from Flow' do
      expect_any_instance_of(Io::Flow::V0::Clients::Experiences).not_to(receive(:get_items_by_number))
      expect(variant).not_to(receive(:flow_import_item))
      subject.run(variant)
    end
  end

  context 'when there is an active experience' do
    before(:each) do
      flow_item = build(:flow_item)
      flow_experience = build(:flow_germany_experience)
      allow_any_instance_of(Io::Flow::V0::Clients::Experiences).to(receive(:get).and_return([flow_experience]))
      allow_any_instance_of(Io::Flow::V0::Clients::Experiences).to(receive(:get_items_by_number).and_return(flow_item))
    end

    context 'when there is no Spree::Zone associated to the experience' do
      it 'does store variant information from Flow' do
        expect_any_instance_of(Io::Flow::V0::Clients::Experiences).not_to(receive(:get_items_by_number))
        expect(variant).not_to(receive(:flow_import_item))
        subject.run(variant)
        expect(variant.reload.flow_data).to(be_blank)
      end
    end

    context 'when there is an Spree::Zone' do
      before(:each) { create(:germany_zone, :with_flow_data) }

      it 'stores variant information from Flow' do
        expect(variant).to(receive(:flow_import_item)).once
        subject.run(variant)
      end
    end
  end
end
