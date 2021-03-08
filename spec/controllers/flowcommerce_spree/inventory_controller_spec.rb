# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

RSpec.describe FlowcommerceSpree::InventoryController, type: :controller do
  describe '#online_stock_availability' do
    let(:variant) { create(:base_variant) }

    it 'returns empty response when items are empty' do
      spree_get :online_stock_availability
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['items']).to(be_empty)
    end

    context 'when items are not empty' do
      it 'returns false when variant does not exist' do
        variant_sku = 'doesnotexists'
        spree_get :online_stock_availability, items: [{ id: variant_sku, qty: 1 }]
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['items']).to(include('id' => variant_sku, 'has_inventory' => false))
      end

      context 'when variant does not have stock' do
        it 'returns has_inventory as false' do
          spree_get :online_stock_availability, items: [{ id: variant.sku, qty: 1 }]
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['items']).to(include('id' => variant.sku, 'has_inventory' => false))
        end
      end

      context 'when variant has stock' do
        before(:each) do
          stock_item = variant.stock_items.first
          stock_item.adjust_count_on_hand(10)
        end

        it 'returns has_inventory as true if enough available stock' do
          spree_get :online_stock_availability, items: [{ id: variant.sku, qty: 1 }]
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['items']).to(include('id' => variant.sku, 'has_inventory' => true))
        end

        it 'returns has_inventory as false if not enough available stock' do
          spree_get :online_stock_availability, items: [{ id: variant.sku, qty: 11 }]
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['items']).to(include('id' => variant.sku, 'has_inventory' => false))
        end
      end
    end
  end
end
