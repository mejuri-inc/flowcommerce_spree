# frozen_string_literal: true

module Users
  SessionsController.class_eval do
    private

    def external_checkout?
      current_zone.flow_io_active_experience? ? 'true' : 'false'
    end
  end
end
