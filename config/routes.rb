# frozen_string_literal: true

FlowcommerceSpree::Engine.routes.draw do
  post '/event-target', to: 'webhooks#handle_flow_web_hook_event'
  get '/order-completed', to: 'orders#order_completed'
  get '/stock', to: 'flow#stock'
end
