# frozen_string_literal: true

require 'rails_helper'
require 'colorize'

module FlowcommerceSpree
  RSpec.describe ImportItemsHsCodes do
    let(:hs_code_data) { build(:flow_hs_code) }

    before do
      allow_any_instance_of(Io::Flow::V0::Clients::Hs10)
        .to(receive(:get).with('mejuridevs', limit: 100, offset: 0).and_return([hs_code_data]))
      allow_any_instance_of(Io::Flow::V0::Clients::Hs10)
        .to(receive(:get).with('mejuridevs', limit: 100, offset: 100).and_return([]))
    end

    it 'Update variant HS code' do
      FlowcommerceSpree::ImportItemsHsCodes.run
      variant = Spree::Variant.find_by(sku: hs_code_data.item.number)
      expect(variant.flow_data['hs_code']).to(eq(hs_code_data.code[0..5]))
    end
  end
end
