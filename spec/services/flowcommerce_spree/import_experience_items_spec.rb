# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::ImportExperienceItems do
  subject { FlowcommerceSpree::ImportExperienceItems }
  let(:variant) { create(:base_variant) }
  let(:flow_experience) { build(:flow_germany_experience) }
  let(:flow_item) { build(:flow_item, number: variant.sku) }
  let(:zone) { create(:germany_zone, :with_flow_data) }

  before(:each) do
    allow(FlowcommerceSpree::ImportExperienceItems).to(receive(:run).and_call_original)
    return_values = [[flow_item], []]
    allow_any_instance_of(Io::Flow::V0::Clients::Experiences).to receive(:get_items) do
      return_values.shift
    end
  end

  context 'when variant exists' do
    let(:flow_item) { build(:flow_item, number: variant.sku) }

    it 'stores variant localized information from Flow' do
      expect_any_instance_of(Spree::Variant).to(receive(:flow_import_item).and_call_original)
      subject.run(zone)
      expect(variant.reload.flow_data).to(be_present)
    end

    context 'when retrieving multiple batches' do
      let(:variant2) { create(:base_variant) }
      let(:flow_item2) { build(:flow_item, number: variant2.sku) }

      before(:each) do
        return_values = [[flow_item],[flow_item2], []]
        allow_any_instance_of(Io::Flow::V0::Clients::Experiences).to receive(:get_items) do
          return_values.shift
        end
      end

      it 'stores all variant`s localized information' do
        expect_any_instance_of(Spree::Variant).to(receive(:flow_import_item).and_call_original)
        subject.run(zone)
        expect(variant.reload.flow_data).to(be_present)
        expect(variant2.reload.flow_data).to(be_present)
      end
    end
  end

  context 'when variant does not exists' do
    let(:flow_item) { build(:flow_item) }

    it 'does not store localized information from Flow' do
      expect_any_instance_of(Spree::Variant).not_to(receive(:flow_import_item))
      subject.run(zone)
    end
  end
end
