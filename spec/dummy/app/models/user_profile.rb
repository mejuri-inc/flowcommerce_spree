# frozen_string_literal: true

class UserProfile < ActiveRecord::Base
  belongs_to :user, touch: true
  delegate :email, to: :user

  has_one :address, dependent: :destroy
  delegate :country, to: :address, allow_nil: true, prefix: true

  validates :user, presence: true

  accepts_nested_attributes_for :user

  validates :hometown, length: { maximum: 100 }
  validates :current_city, length: { maximum: 100 }
  validate :valid_age

  store_accessor :extra_data, :postal_code
  validates :postal_code, length: { maximum: 6 }

  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def full_name_capitalized
    (first_name + ' ' + last_name).split(' ').map{|name| name.capitalize}.join(' ') if !first_name.nil? && !last_name.nil?
  end

  def full_name_or_username
    if !user.nil?
      full_name.blank? ? user.short_username : full_name_capitalized
    else
      ''
    end
  end

  def location
    location = current_city || ''
    location += ', ' if !current_city.blank? && !country.blank?
    location += country || ''
  end

  def to_s
    full_name_or_username
  end

  def to_liquid
    { first_name: first_name, last_name: last_name, full_name: full_name }
  end

  def missing_info?
    first_name.blank? || last_name.blank?
  end

  ####### Address interaction API ######
  def update_shipping_address(address_params)
    shipping_address = self.address || self.build_address
    shipping_address.assign_attributes(address_params)
    shipping_address.save
  end

  def get_shipping_address
    return address if address&.valid?

    last_address = shipping_address_from_last_order
    return unless last_address.present?

    self.address = last_address
    save
    address
  end

  def shipping_address_from_last_order
    completed_orders = orders.completed.reject(&:pick_up?)
    return if completed_orders.empty?

    default_shipping_address = completed_orders.first.shipping_address
    Address.new(default_shipping_address.attributes.except('id', 'created_at', 'updated_at', 'company', 'email'))
  end

  def default_address_for_spree
    address = get_shipping_address
    if address
      Spree::Address
        .new(address.attributes.except('id', 'created_at', 'updated_at', 'company', 'email', 'user_profile_id'))
    else
      Spree::Address.default
    end
  end

  def orders
    Spree::Order.where(
      "email = '#{email}' OR user_id = '#{user_id}' AND state IN ('complete','canceled','returned')"
    ).order('completed_at DESC')
  end

  def owns_order?(order)
    order.email == email
  end

  def orders_since(date)
    orders.get_from_dates(date)
  end

  def order_history_start_date
    Date.new(2016,11,01)
  end

  def orders_since_beggining_of_history
    orders_since(order_history_start_date)
  end

  def orders_for_display
    orders_since_beggining_of_history.limit(30)
  end

  def orders_available_for_return
    orders.select(&:available_for_return?)
  end

  def items_available_for_return
    orders_available_for_return.map(&:items_available_for_return).flatten
  end

  protected

  def valid_age
    return unless birthday

    min_age = 13
    now = Time.now.utc.to_date
    age = now.year - birthday.year - (birthday.to_date.change(year: now.year) > now ? 1 : 0)
    errors.add(:birthday, 'Must be 13 or older') if age < min_age
  end
end
