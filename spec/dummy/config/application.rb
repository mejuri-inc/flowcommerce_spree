# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'rails/all'

Bundler.require(:default, :development, :test)

require 'flowcommerce_spree'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.to_prepare do
      # Load application's model  class decorators
      Dir.glob(File.join(File.dirname(__FILE__), '../app/**/*_decorator*.rb')).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # TODO: Remove on Rails 4.2.x and factory_bot v.5.x.x, where it was implemented
      # https://github.com/thoughtbot/factory_bot/commit/0c17434b4a35256a20e5ce60559345e398f64721
      if Rails.env.test?
        Dir.glob(File.join(File.dirname(__FILE__), '../lib/factory_bot/**/*_decorator*.rb')).sort.each do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end
    end
  end
end
