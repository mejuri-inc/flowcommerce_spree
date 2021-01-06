# frozen_string_literal: true

CurrentZoneLoader.module_eval do
  extend ActiveSupport::Concern

  def flow_zone # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    return unless Spree::Zones::Product.active
                                       .where("meta -> 'flow_data' ->> 'country' = ?",
                                                ISO3166::Country[request_iso_code]&.alpha3).exists?

    request_ip =
      if Rails.env.production?
        request.ip
      else
        Spree::Config[:debug_request_ip_address] || request.ip
        # Germany ip: 85.214.132.117, Sweden ip: 62.20.0.196, Moldova ip: 89.41.76.29
      end
    flow_io_session = FlowcommerceSpree::Session
                      .new(ip: request_ip, visitor: visitor_id_for_flow_io)
    # :create method will issue a request to flow.io. The experience, contained in the
    # response, will be available in the session object - flow_io_session.experience
    flow_io_session.create
    zone = Spree::Zones::Product.active.find_by(name: flow_io_session.experience&.key&.titleize)
    session['_f60_session'] = flow_io_session.id if zone
    zone
  end

  # composes an unique vistor id for FlowcommerceSpree::Session model
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

  def fetch_product_for_zone(product)
    Rails.cache.fetch(
      "product_zone_#{current_zone.name}_#{product.sku}", expires_in: 1.day,
                                                          race_condition_ttl: 10.seconds, compress: true
    ) do
      Spree::Zones::Product.find_product_for_zone(product, current_zone)
    end
  end
end
