# frozen_string_literal: true

FactoryBot.define do
  factory :payment_capture_event, class: Spree::PaymentCaptureEvent do
    payment
    amount { 100.00 }
  end
end
