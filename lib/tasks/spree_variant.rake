# frozen_string_literal: true

namespace :spree_variant do
  desc 'Import Flow Hs Codes from CSV'
  task import_flow_hs_code_from_csv: :environment do
    s3_file_path = CSVUploader.download_url('script/flow_hs_codes.csv', 'flow_hs_code')
    csv = CSV.new(URI.parse(s3_file_path).open, headers: true, col_sep: ',')

    not_found = []
    updated = []
    with_errors = []

    csv.each do |row|
      begin
        hs_code = row['hs6']
        next unless hs_code.present?

        sku = row['item_number']
        next not_found << sku unless (variant = Spree::Variant.find_by(sku: row['item_number']))

        variant.flow_data ||= {}
        variant.flow_data['hs_code'] = hs_code
        variant.update_column(:meta, variant.meta.to_json)
        updated << sku
      rescue StandardError
        with_errors << sku
      end
    end

    VariantService.new.update_flow_classification(updated)

    puts "\n#{Time.zone.now} | Not found in the DB #{not_found.size}."
    puts not_found.inspect

    puts "\n#{Time.zone.now} | Unexpected errors while updating #{with_errors.size}."
    puts with_errors.inspect

    puts "\n#{Time.zone.now} | Updated #{updated.size}."
    puts "Updated #{updated} variants."
  end

  desc 'Import Flow Hs Codes from Api'
  task import_flow_hs_code: :environment do
    FlowcommerceSpree::ImportItemsHsCodes.run
  end
end
