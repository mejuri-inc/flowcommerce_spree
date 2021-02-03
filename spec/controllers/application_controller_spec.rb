# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'shared_examples/current_zone_loader'

RSpec.describe ApplicationController, type: :controller do
  it_behaves_like 'current_zone_loader'
end
