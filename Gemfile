# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'byebug', '11.0.1'
  gem 'countries'
  gem 'devise'
  gem 'dotenv-rails', require: 'dotenv/rails-now'
  gem 'rails', '4.1.16'
  gem 'rubocop', '~> 0.78.0', require: false
  gem 'rubocop-performance', '1.5.2', require: false
  gem 'rubocop-rails', '2.5.2', require: false
  gem 'rubocop-rspec', '1.38.1', require: false
  gem 'sidekiq', '~> 4.0', '>= 4.0.2'
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-mocks', git: 'https://github.com/mejuri-inc/rspec-mocks'
  gem 'rspec-sidekiq'
  gem 'simplecov', require: false
end
