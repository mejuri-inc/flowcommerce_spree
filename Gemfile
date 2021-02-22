# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'activerecord-postgres-json', '>= 0.2.3'
  gem 'byebug', '11.0.1'
  gem 'countries'
  gem 'devise'
  gem 'dotenv-rails', require: 'dotenv/rails-now'
  gem 'factory_bot_rails', '~> 4.0'
  gem 'oj', '= 3.7.12'
  gem 'rails', '4.1.16'
  gem 'rspec-rails', '~> 3.5'
  gem 'rubocop', '~> 0.78.0', require: false
  gem 'rubocop-performance', '1.5.2', require: false
  gem 'rubocop-rails', '2.5.2', require: false
  gem 'rubocop-rspec', '1.38.1', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-mocks', git: 'https://github.com/mejuri-inc/rspec-mocks'
end
