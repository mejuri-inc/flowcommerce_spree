# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'dotenv-rails', require: 'dotenv/rails-now'

  gem 'rubocop', '~> 0.78.0', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  gem 'rspec-rails', '~> 3.5'

  gem 'activerecord-postgres-json', '>= 0.2.3'
  gem 'byebug'
  gem 'countries'
  gem 'devise'
  gem 'factory_bot_rails', '~> 4.0'
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-mocks', git: 'https://github.com/mejuri-inc/rspec-mocks'
end
