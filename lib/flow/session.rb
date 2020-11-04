# Flow.io (2017)
# communicates with flow api, easy access to session

class Flow::Session
  attr_accessor :session, :localized, :visitor

  def self.restore packed_session
    Marshal.load packed_session
  end

  # flow session can ve created via IP or local cached OrganizationSession dump
  # FlowcommerceSpree::ExperienceService.all.first.key
  # Flow sessions need buest-guess visitor_id and
  def initialize ip:, visitor:
    ip = '127.0.0.1' if ip == '::1'

    @ip      = ip
    @visitor = visitor
  end

  # create session with blank data
  def create
    data = {
      ip:    @ip,
      visit: {
        id:         @visitor,
        expires_at: (Time.now+30.minutes).iso8601
      }
    }

    session_model = ::Io::Flow::V0::Models::SessionForm.new data
    @session      = FlowcommerceSpree.client.sessions.post_organizations_by_organization FlowcommerceSpree::ORGANIZATION, session_model
  end

  # if we want to manualy switch to specific country or experience
  def update data
    @session = FlowcommerceSpree.client.sessions.put_by_session(
      @session.id,
      ::Io::Flow::V0::Models::SessionPutForm.new(data)
    )
  end

  def dump
    Marshal.dump self
  end

  # get local experience or return nil
  def experience
    @session.local ? @session.local.experience : FlowcommerceSpree::ExperienceService.default
  end

  def local
    @session.local
  end

  def id
    @session.id
  end

  def localized?
    # use flow if we are not in default country
    return false unless local
    return false if @localized.class == FalseClass
    local.country.iso_3166_3 != ENV.fetch('FLOW_BASE_COUNTRY').upcase
  end

  # because we do not get full experience from session, we have to get from exp list
  def delivered_duty_options
    return nil unless experience

    if flow_experience = FlowcommerceSpree::ExperienceService.get(experience.key)
      Hashie::Mash.new flow_experience.settings.delivered_duty.to_hash
    else
      nil
    end
  end

  # if we have more than one choice, we show choice popup
  def offers_delivered_duty_choice?
    if options = delivered_duty_options
      options.available.length > 1
    else
      false
    end
  end
end

