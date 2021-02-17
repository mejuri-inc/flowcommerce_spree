# frozen_string_literal: true

module Spree
  module FlowIoCreditCardDecorator
    def self.prepended(base)
      base.serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

      base.store_accessor :meta, :flow_data
    end

    def push_authorization(auth_hash)
      self.flow_data ||= {}
      flow_data['authorizations'] ||= []
      card_authorizations = flow_data['authorizations']
      card_authorizations.delete_if { |ca| ca['id'] == auth_hash['id'] }
      card_authorizations << auth_hash
    end

    Spree::CreditCard.prepend(self) if Spree::CreditCard.included_modules.exclude?(self)
  end
end
