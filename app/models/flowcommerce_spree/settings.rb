# frozen_string_literal: true

module FlowcommerceSpree
  class Settings < Spree::Preferences::Configuration
    preference :additional_attributes, :hash, default: {}
    preference :product_catalog_upload, :hash, default: {}
    preference :notification_setting, :hash, default: {}
  end
end
