# frozen_string_literal: true

require 'ffaker/utils/array_utils'
require 'ffaker/utils/unique_utils'

# TODO: Remove on ffaker v.2.7.0, where it was implemented
module Faker
  module ModuleUtils
    def unique(max_retries = 10_000)
      @unique ||= Faker::UniqueUtils.new(self, max_retries)
    end
  end
end
