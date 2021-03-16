# frozen_string_literal: true

Api::V2::OrderSerializer.class_eval do
  attribute :duty_included, if: proc { object.flow_io_attributes.present? }
  attribute :vat_included, if: proc { object.flow_io_attributes.present? }

  def duty_included
    flow_io_order_attributes&.[]('duty') == 'included'
  end

  def vat_included
    flow_io_order_attributes&.[]('vat') == 'included'
  end

  private

  def flow_io_order_attributes
    @flow_io_order_attributes ||= Oj.load(object.flow_io_attributes['pricing_key'])
  end
end
