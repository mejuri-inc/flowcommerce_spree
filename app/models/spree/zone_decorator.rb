module Spree
  Zone.class_eval do
    store_accessor :options, :flow_data
  end
end
