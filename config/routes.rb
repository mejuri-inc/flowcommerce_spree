FlowcommerceSpree::Engine.routes.draw do
    post '/event-target',         to: 'webhooks#handle_flow_web_hook_event'
    get '/stock', to: 'flow#stock'
end
