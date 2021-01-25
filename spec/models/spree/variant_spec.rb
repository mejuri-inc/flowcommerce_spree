# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Variant, type: :model do
  describe '#truncate_flow_data' do
    context 'when variant has flow_data' do
      let(:variant) { create(:base_variant, :with_flow_data) }
      let(:spree_zone) { Spree::Zones::Product.find_by(name: 'Germany') }

      it 'deletes flow data' do
        variant.truncate_flow_data
        expect(variant.flow_data).to(be_nil)
      end

      it 'removes product from Spree::Zones' do
        expect(variant.product.zone_ids).to(be_present)
        variant.truncate_flow_data
        expect(variant.product.zone_ids).to(be_empty)
      end
    end
  end

  describe '#remove_experience_from_product' do
    context 'when variant has multiple experiences assocaited' do
      let(:variant) { create(:base_variant, :with_flow_data) }
      let(:spree_zone) { Spree::Zones::Product.find_by(name: 'Germany') }
      let(:spree_zone2) { Spree::Zones::Product.find_by(name: 'France') }

      it 'removes only the experience defined' do
        expect(variant.product.zone_ids).to(match_array([spree_zone.id.to_s, spree_zone2.id.to_s]))
        variant.remove_experience_from_product('germany', variant.product)

        expect(variant.product.zone_ids).to(be_present)
        expect(variant.product.zone_ids).to(match_array([spree_zone2.id.to_s]))
      end
    end
  end

  describe '#flow_local_price' do
    describe 'when variant has flow_data' do
      let(:variant) { create(:base_variant, :with_flow_data) }

      context 'when experience exists' do
        let(:experience) { 'germany' }

        it 'returns price in experience currency' do
          flow_local_price = variant.flow_local_price(experience)
          flow_price_amount = variant.flow_data['exp'][experience]['prices'][0]['amount']

          expect(flow_local_price.currency).to(eq('EUR'))
          expect(flow_local_price.price).to(eq(flow_price_amount))
        end
      end

      context 'when experience does not exists' do
        let(:experience) { 'randomcountry' }

        it 'returns price in USD' do
          flow_local_price = variant.flow_local_price(experience)

          expect(variant.meta[:flow_data][:exp].keys).not_to(include(experience))
          expect(flow_local_price.currency).to(eq('USD'))
          expect(flow_local_price.price).to(eq(variant.price))
        end
      end
    end
  end

  describe '#price_in_zone' do
    describe 'when Spree::Zone has experience in flow' do
      let(:variant) { create(:base_variant, :with_flow_data) }
      let(:spree_zone) { Spree::Zones::Product.find_by(name: 'Germany') }
      let(:experience) { 'germany' }

      it 'returns price in zone regardles of currency pass' do
        price_in_zone = variant.price_in_zone('USD', spree_zone)
        flow_price_amount = variant.flow_data['exp'][experience]['prices'][0]['amount']

        expect(price_in_zone.currency).to(eq('EUR'))
        expect(price_in_zone.amount).to(eq(flow_price_amount))
      end
    end

    context 'when Spree::Zone does not have flow_data' do
      let(:variant) { create(:base_variant, :with_cad_price, :with_aud_price, :with_gbp_price) }
      let(:spree_zone) { create(:germany_zone) }

      it 'returns price in selected currency' do
        %w[USD CAD AUD GBP].each do |currency|
          price_in_zone = variant.price_in_zone(currency, spree_zone)
          variant_price = Spree::Price.find_by(variant_id: variant.id, currency: currency)

          expect(spree_zone.meta).to(eq({}))
          expect(price_in_zone.currency).to(eq(currency))
          expect(price_in_zone.amount).to(eq(variant_price.amount))
        end
      end
    end
  end

  describe '#all_prices_in_zone' do
    describe 'when variant has flow_data' do
      let(:variant) { create(:base_variant, :with_flow_data) }

      context 'when zone has flow experience' do
        it 'includes flow price' do
          spree_zone = create(:germany_zone, :with_flow_data)
          all_prices = variant.all_prices_in_zone(spree_zone)

          flow_price = variant.flow_local_price('germany')
          expect(all_prices).to(include({ amount: variant.price.round.to_s, currency: 'USD' }))
          expect(all_prices).to(include({ amount: flow_price.amount.round.to_s, currency: flow_price.currency }))
        end
      end

      context 'when zone does not have flow experience' do
        it 'does not include flow price' do
          spree_zone = create(:germany_zone)
          all_prices = variant.all_prices_in_zone(spree_zone)

          flow_price = variant.flow_local_price('germany')
          expect(all_prices).to(include({ amount: variant.price.round.to_s, currency: 'USD' }))
          expect(all_prices).not_to(include({ amount: flow_price.amount.round.to_s, currency: flow_price.currency }))
        end
      end
    end

    context 'when variant does not have flow_data' do
      let(:variant) { create(:base_variant) }

      it 'returns all_prices' do
        spree_zone = create(:germany_zone)
        all_prices = variant.all_prices_in_zone(spree_zone)

        expect(all_prices).to(eq([{ amount: variant.price.round.to_s, currency: 'USD' }]))
      end
    end
  end
end
