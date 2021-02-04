# frozen_string_literal: true

class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  has_one :user_profile, dependent: :destroy
  accepts_nested_attributes_for :user_profile

  before_save :generate_spree_api_key!, if: -> { spree_api_key.nil? }

  def profile
    unless user_profile
      create_user_profile
      save!(validate: false)
    end

    user_profile
  end
end
