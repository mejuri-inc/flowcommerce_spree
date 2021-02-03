# frozen_string_literal: true

class Address < ActiveRecord::Base
  belongs_to :user_profile

  validates :firstname, :lastname, :address1, :city, :zipcode, :country_id, presence: true
  validate :valid_state

  def country
    Spree::Country.find(country_id) unless country_id.nil?
  end

  def state
    if country.states.none?
      state_name
    elsif state_id && state_id > 0
      Spree::State.find(state_id).name
    end
  end

  private

  def valid_state
    errors.add(:base, 'state_required') if state_name.blank? && state_id.blank?
  end
end
