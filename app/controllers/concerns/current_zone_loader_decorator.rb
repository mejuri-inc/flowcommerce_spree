# frozen_string_literal: true

CurrentZoneLoader.module_eval do
  extend ActiveSupport::Concern

  def current_zone
    return @current_zone if defined?(@current_zone)

    @current_zone = if (session_region_name = session['region']&.[](:name))
                      Spree::Zones::Product.find_by(name: session_region_name, status: 'active')
                    end

    @current_zone ||= fetch_current_zone
    @current_zone
  end

  def fetch_current_zone
    if request_iso_code.present?
      @current_zone = flow_zone || Spree::Country.find_by(iso: request_iso_code)&.product_zones&.active&.first
    end

    @current_zone ||= Spree::Zones::Product.find_by(name: 'International') ||
                      Spree::Zones::Product.new(name: 'International', taxon_ids: [], currencies: %w[USD CAD])

    current_zone_name = @current_zone.name
    session['region'] = { name: current_zone_name, available_currencies: @current_zone.available_currencies,
                          request_iso_code: request_iso_code }
    Rails.logger.debug("Using product zone: #{current_zone_name}")

    @current_zone
  end

  def flow_zone
    return unless Spree::Zones::Product.active
                                       .where("meta -> 'flow_data' ->> 'country' = ?",
                                              ISO3166::Country[request_iso_code]&.alpha3).exists?

    # This will issue a session creation request to flow.io. The response will contain the Flow Experience key and
    # the session_id
    flow_io_session = FlowcommerceSpree::Session.create(country: request_iso_code, visitor: visitor_id_for_flow_io)

    if (zone = Spree::Zones::Product.active.find_by(name: flow_io_session.experience&.key&.titleize))
      session['flow_session_id'] = flow_io_session.id
    end

    zone
  end

  # composes an unique visitor id for FlowcommerceSpree::Session model
  def visitor_id_for_flow_io
    guest_token = cookies.signed[:guest_token]
    uid = if guest_token
            Digest::SHA1.hexdigest(guest_token)
          else
            session_id = session[:session_id]
            session_id ? Digest::SHA1.hexdigest(session_id) : Digest::SHA1.hexdigest(request.ip + request.user_agent)
          end

    "session-#{uid}"
  end
end
