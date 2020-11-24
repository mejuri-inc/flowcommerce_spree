# frozen_string_literal: true

CurrentZoneLoader.module_eval do
  extend ActiveSupport::Concern

  def current_zone
    return @current_zone if defined?(@current_zone)

    @current_zone = if (session_region_name = session['region']&.[]('name'))
                      Spree::Zones::Product.find_by(name: session_region_name)
                    elsif request_iso_code.present?
                      flow_io_zones = Spree::Zones::Product.active.where(
                          "meta -> 'flow_data' ->> 'country' = ?", ISO3166::Country[request_iso_code]&.alpha3
                        ).all.to_a
                      if flow_io_zones.present?
                        if flow_io_zones.size > 1
                          # TODO: Remove debug comments below
                          # flow_io_session = FlowcommerceSpree::Session
                          #                     .new(ip: '85.214.132.117', visitor: visitor_id_for_flow_io) # Germany
                          # flow_io_session = FlowcommerceSpree::Session
                          #                     .new(ip: '62.20.0.196', visitor: visitor_id_for_flow_io) # Sweden
                          # flow_io_session = FlowcommerceSpree::Session
                          #                     .new(ip: '89.41.76.29', visitor: visitor_id_for_flow_io) # Moldova
                          flow_io_session = FlowcommerceSpree::Session
                                              .new(ip: request.ip, visitor: visitor_id_for_flow_io)
                          # :create method will issue a request to flow.io. The experience, contained in the
                          # response, will be available in the session object - flow_io_session.experience
                          flow_io_session.create
                          Spree::Zones::Product.active.find_by(name: flow_io_session.experience&.key&.titleize)
                        else
                          flow_io_zones.first
                        end
                      else
                        Spree::Country.find_by(iso: request_iso_code)&.product_zones&.active&.first
                      end
                    end

    @current_zone ||= Spree::Zones::Product.find_by(name: 'International')
    @current_zone ||= Spree::Zones::Product.new(name: 'International', taxon_ids: [], currencies: %w[USD CAD])
    session['region'] = { name: @current_zone.name, available_currencies: @current_zone.available_currencies }
    Rails.logger.debug("Using product zone: #{@current_zone.name}")
    @current_zone
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
