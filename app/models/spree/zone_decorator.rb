module Spree
  Zone.class_eval do
    store_accessor :meta, :flow_data
  end
end
