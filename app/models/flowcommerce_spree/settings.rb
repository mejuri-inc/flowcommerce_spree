module FlowcommerceSpree
  class Settings < Spree::Preferences::Configuration
    preference :product_catalog_upload, :hash, default: {}
  end
end
