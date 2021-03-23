# frozen_string_literal: true

class VariantService
  attr_accessor :variant

  def initialize(variant = nil)
    @variant = variant
  end

  def update_flow_classification(variant_skus = []); end
end
