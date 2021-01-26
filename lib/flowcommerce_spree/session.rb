# frozen_string_literal: true

# communicates with flow.io api, easy access to session
module FlowcommerceSpree
  class Session
    attr_accessor :session, :localized, :visitor

    def self.create(ip:, visitor:, experience: nil)
      instance = new(ip: ip, visitor: visitor, experience: experience)
      instance.create
      instance
    end

    def initialize(ip:, visitor:, experience: nil)
      ip = '127.0.0.1' if ip == '::1'

      @ip      = ip
      @visitor = visitor
      @experience = experience
    end

    # create session without or with experience (the latter is useful for creating a new session with the order's
    # experience on refreshing the checkout_token)
    def create
      data = { ip: @ip,
               visit: { id: @visitor,
                        expires_at: (Time.now + 30.minutes).iso8601 } }
      data[:experience] = @experience if @experience

      session_model = ::Io::Flow::V0::Models::SessionForm.new data
      @session = FlowCommerce.instance(http_handler: LoggingHttpHandler.new)
                             .sessions.post_organizations_by_organization(ORGANIZATION, session_model)
    end

    # if we want to manually switch to specific country or experience
    def update(data)
      @session = FlowCommerce.instance.sessions.put_by_session(@session.id,
                                                               ::Io::Flow::V0::Models::SessionPutForm.new(data))
    end

    # get local experience or return nil
    def experience
      @session.local&.experience
    end

    def expires_at
      @session.visit.expires_at
    end

    def local
      @session.local
    end

    def id
      @session.id
    end

    # because we do not get full experience from session, we have to get from exp list
    def delivered_duty_options
      return nil unless experience

      return unless (flow_experience = Flow::Experience.get(experience.key))

      Hashie::Mash.new(flow_experience.settings.delivered_duty.to_hash)
    end

    # if we have more than one choice, we show choice popup
    def offers_delivered_duty_choice?
      if (options = delivered_duty_options)
        options.available.length > 1
      else
        false
      end
    end
  end
end
