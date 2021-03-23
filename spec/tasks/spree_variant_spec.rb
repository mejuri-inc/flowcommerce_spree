# frozen_string_literal: true

require 'rails_helper'
require 'csv'

describe 'rake products:turn_on_version_for_region', type: :task do
  let(:variant) { create(:base_variant, :with_flow_data) }

  describe 'import_flow_hs_code_from_csv' do
    let(:hs_code) { '711319' }
    let(:stubed_csv_content) { [variant.sku, hs_code, variant.product.id, variant.product.name] }
    let(:stubed_csv) { CSV.new("item_number,hs6,product_id,item_name\n#{stubed_csv_content.join(',')}", headers: true) }
    let(:run_codes_rake_task) do
      Rake::Task['spree_variant:import_flow_hs_code_from_csv'].reenable
      Rake.application.invoke_task('spree_variant:import_flow_hs_code_from_csv')
    end

    before(:each) do
      allow(CSVUploader).to(receive(:download_url).and_return('https://s3.amazonaws.com/test/script/flow_hs_codes.csv'))
      allow_any_instance_of(URI::HTTPS).to(receive(:open))

      allow(CSV).to(receive(:new).and_return(stubed_csv))
    end

    it 'updates variant`s flow data with the hs_code' do
      expect(variant.flow_data['hs_code']).to(be_blank)
      run_codes_rake_task
      expect(variant.reload.flow_data['hs_code']).to(eq(hs_code))
    end

    it 'Calls VariantService#update_flow_classification method' do
      expect_any_instance_of(VariantService).to(receive(:update_flow_classification).with([variant.sku]))
      run_codes_rake_task
    end
  end
end
