# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Product, type: :model do
  describe '#flow_local_price' do
    describe 'when variant has flow_data' do
      let(:product) { create(:product, :with_master_variant_flow_data) }

      context 'when experience exists' do
        let(:experience) { 'germany' }

        it 'returns price in experience currency' do
          flow_local_price = product.flow_local_price(experience)
          flow_price_amount = product.master.flow_data['exp'][experience]['prices'][0]['amount']

          expect(flow_local_price.currency).to(eq('EUR'))
          expect(flow_local_price.price).to(eq(flow_price_amount))
        end
      end

      context 'when experience does not exists' do
        let(:experience) { 'randomcountry' }

        it 'returns price in USD' do
          variant = product.master
          flow_local_price = product.flow_local_price(experience)

          expect(variant.meta[:flow_data][:exp].keys).not_to(include(experience))
          expect(flow_local_price.currency).to(eq('USD'))
          expect(flow_local_price.price).to(eq(variant.price))
        end
      end
    end
  end

  describe '#price_in_zone' do
    describe 'when Spree::Zone has experience in flow_io' do
      let(:product) { create(:product, :with_master_variant_flow_data) }
      let(:spree_zone) { Spree::Zones::Product.find_by(name: 'Germany') }
      let(:experience) { 'germany' }

      it 'returns price in zone regardles of currency pass' do
        price_in_zone = product.price_in_zone('USD', spree_zone)
        flow_price_amount = product.master.flow_data['exp'][experience]['prices'][0]['amount']

        expect(price_in_zone.currency).to(eq('EUR'))
        expect(price_in_zone.amount).to(eq(flow_price_amount))
      end
    end

    context 'when Spree::Zone does not have flow_data' do
      let(:product) { create(:product, :with_cad_price, :with_aud_price, :with_gbp_price) }
      let(:spree_zone) { create(:germany_zone) }

      it 'returns price in selected currency' do
        %w[USD CAD AUD GBP].each do |currency|
          price_in_zone = product.price_in_zone(currency, spree_zone)
          variant_price = Spree::Price.find_by(variant_id: product.master.id, currency: currency)

          expect(spree_zone.meta).to(eq({}))
          expect(price_in_zone.currency).to(eq(currency))
          expect(price_in_zone.amount).to(eq(variant_price.amount))
        end
      end
    end
  end

  describe '#price_range' do
    RSpec.shared_examples 'only_currencies_in_master_variant' do
      it 'does not return prices in currency not included in master variant' do
        price_ranges = product.price_range(spree_zone)

        expect(product.master.prices.pluck(:currency)).not_to(include('GBP'))
        expect(price_ranges['GBP']).to(be_nil)
      end
    end

    describe 'when Spree::Zone does has experience in flow_io' do
      let(:product) { create(:product, :with_master_variant_flow_data, :with_cad_price, :with_aud_price) }
      let(:variant1) { create(:base_variant, :with_flow_data, product: product) }
      let(:variant2) { create(:base_variant, :with_flow_data, product: product) }
      let(:spree_zone) { Spree::Zones::Product.find_by(name: 'Germany') }

      describe 'when variants have same price' do
        it 'includes currency for flow_io experience' do
          price_ranges = product.price_range(spree_zone)
          master_flow_price = product.master.flow_local_price(spree_zone.flow_data['key']).amount.round.to_s

          price_range_hash = { max: product.price.round.to_s, min: product.price.round.to_s }
          expect(price_ranges['USD']).to eq(price_range_hash)
          expect(price_ranges['CAD']).to eq(price_range_hash)
          expect(price_ranges['AUD']).to eq(price_range_hash)
          expect(price_ranges['EUR']).to eq(max: master_flow_price, min: master_flow_price)
        end

        include_examples 'only_currencies_in_master_variant'
      end

      describe 'when variants have different prices' do
        let(:min_price) { 100 }
        let(:max_price) { 1000 }

        before(:each) do
          variant1.meta[:flow_data][:exp][:germany][:prices][0][:amount] = min_price
          variant1.update_columns(meta: variant1.meta.to_json)

          variant2.meta[:flow_data][:exp][:germany][:prices][0][:amount] = max_price
          variant2.update_columns(meta: variant2.meta.to_json)
        end

        it 'returns price ranges for currencies' do
          price_ranges = product.reload.price_range(spree_zone)

          expect(price_ranges['EUR']).to(eq(min: min_price.to_s, max: max_price.to_s))
        end

        include_examples 'only_currencies_in_master_variant'
      end
    end

    describe 'when Spree::Zone does not have experience in flow_io' do
      let(:product) { create(:product, :with_cad_price, :with_aud_price) }
      let(:variant1) { create(:base_variant, product: product) }
      let(:variant2) { create(:base_variant, product: product) }
      let(:spree_zone) { Spree::Zones::Product.find_by(name: 'Germany') }

      describe 'when variants have same price' do
        it 'returns amount for each currency' do
          price_ranges = product.reload.price_range(spree_zone)
          price_range_hash = { max: product.price.round.to_s, min: product.price.round.to_s }
          expect(price_ranges['USD']).to eq(price_range_hash)
          expect(price_ranges['CAD']).to eq(price_range_hash)
          expect(price_ranges['AUD']).to eq(price_range_hash)
        end

        it 'returns amount for each currency received in currencies parameter' do
          price_ranges = product.reload.price_range(spree_zone, %w[USD AUD])
          price_range_hash = { max: product.price.round.to_s, min: product.price.round.to_s }
          expect(price_ranges['USD']).to eq(price_range_hash)
          expect(price_ranges['CAD']).to be_nil
          expect(price_ranges['AUD']).to eq(price_range_hash)
        end

        include_examples 'only_currencies_in_master_variant'
      end

      describe 'when variants have different prices' do
        let(:min_price) { 100 }
        let(:max_price) { 1000 }

        before(:each) do
          %w[USD CAD AUD GBP].each do |currency|
            Spree::Price.find_or_create_by(variant_id: variant1.id, currency: currency)
                        .update_attribute(:amount, min_price)
            Spree::Price.find_or_create_by(variant_id: variant2.id, currency: currency)
                        .update_attribute(:amount, max_price)
          end
        end

        it 'returns price ranges for currencies' do
          price_ranges = product.reload.price_range(spree_zone)
          expect(price_ranges['USD']).to(eq(min: min_price.to_s, max: max_price.to_s))
          expect(price_ranges['CAD']).to(eq(min: min_price.to_s, max: max_price.to_s))
          expect(price_ranges['AUD']).to(eq(min: min_price.to_s, max: max_price.to_s))
        end

        include_examples 'only_currencies_in_master_variant'
      end
    end
  end
end
