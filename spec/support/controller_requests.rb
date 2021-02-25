# frozen_string_literal: true

module ControllerRequests
  def spree_get(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, 'GET')
  end

  # Executes a request simulating POST HTTP method and set/volley the response
  def spree_post(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, 'POST')
  end

  # Executes a request simulating PUT HTTP method and set/volley the response
  def spree_put(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, 'PUT')
  end

  # Executes a request simulating DELETE HTTP method and set/volley the response
  def spree_delete(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, 'DELETE')
  end

  private

  def process_spree_action(action, parameters = nil, session = nil, flash = nil, method = 'GET')
    parameters ||= {}
    process(action, method, parameters.merge!(use_route: :spree), session, flash)
  end
end
