# frozen_string_literal: true

# TODO: Remove on Rails 4.2.x and factory_bot v.5.x.x, where it was implemented
# https://github.com/thoughtbot/factory_bot/commit/0c17434b4a35256a20e5ce60559345e398f64721
module FactoryBot
  class Decorator
    AttributeHash.class_eval do
      def attributes
        @attributes.each_with_object({}) do |attribute_name, result|
          result[attribute_name] = @component.send(attribute_name)
        end
      end
    end
  end
end
