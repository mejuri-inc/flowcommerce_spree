# frozen_string_literal: true

CurrentZoneLoader.module_eval do
  extend ActiveSupport::Concern

  def current_zone
    return @current_zone if defined?(@current_zone)

    @current_zone = if (session_region_name = session['region']&.[]('name'))
                      Spree::Zones::Product.find_by(name: session_region_name)
                    elsif request_iso_code.present?
                      Spree::Country.find_by(iso: request_iso_code)&.product_zones&.active&.first
                    end

    unless @current_zone
      # TODO: Remove debug comments below
      # flow_io_session = FlowcommerceSpree::Session.new ip: '85.214.132.117', visitor: session[:session_id] # Germany
      # flow_io_session = FlowcommerceSpree::Session.new ip: '62.20.0.196', visitor: session[:session_id] # Sweden
      # flow_io_session = FlowcommerceSpree::Session.new ip: '89.41.76.29', visitor: visitor_id_for_flowcommerce # Moldova
      flow_io_session = FlowcommerceSpree::Session.new(ip: request.ip, visitor: visitor_id_for_flowcommerce)
      flow_io_session.create
      @current_zone = Spree::Zones::Product.find_by(name: flow_io_session.experience&.key&.titleize)
    end

    @current_zone ||= Spree::Zones::Product.find_by(name: 'Eligible countries')
    @current_zone ||= Spree::Zones::Product.new(name: 'Eligible countries', currencies: %w[USD CAD])
    session['region'] = { name: @current_zone.name, available_currencies: @current_zone.available_currencies }
    Rails.logger.debug("Using product zone: #{@current_zone.name}")
    @current_zone
  end

  # tries to get vunique vistor id, based on user agent and ip
  def visitor_id_for_flowcommerce
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
