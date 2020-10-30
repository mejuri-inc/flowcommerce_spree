module FlowcommerceSpree
  class Settings < Spree::Preferences::Configuration
    preference :additional_attributes, :hash, default: {}
    preference :product_catalog_upload, :hash, default: {}
  end
end
