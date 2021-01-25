# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Spree::Variant).to receive(:sync_product_to_flow)
  end
end
