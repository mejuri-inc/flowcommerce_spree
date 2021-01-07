# frozen_string_literal: true

Rails.application.routes.draw do
  mount FlowcommerceSpree::Engine => '/flowcommerce_spree'
end
