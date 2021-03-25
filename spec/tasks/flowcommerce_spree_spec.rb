# frozen_string_literal: true

require 'rails_helper'
require 'csv'

describe 'rake flowcommerce_spree', type: :task do
  let(:product) { create(:product) }

  describe 'upload_catalog' do
    let(:run_codes_rake_task) do
      Rake::Task['flowcommerce_spree:upload_catalog'].reenable
      Rake.application.invoke_task('flowcommerce_spree:upload_catalog')
    end

    context 'when country_of_origin is not present' do
      it 'should not syncrhonize data' do
        expect_any_instance_of(Spree::Variant).not_to(receive(:sync_product_to_flow))
        run_codes_rake_task
      end
    end

    context 'when country_of_origin is present' do
      before(:each) do
        product.update_columns(country_of_origin: 'TH')
        expect_any_instance_of(Spree::Variant).to(receive(:sync_product_to_flow).once)
      end

      it 'should call syncrhonize method' do
        run_codes_rake_task
      end
    end
  end
end
