# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'flowcommerce_spree/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'flowcommerce_spree'
  s.version     = FlowcommerceSpree::VERSION
  s.authors     = ['Aurel Branzeanu', 'Sebastian De Luca']
  s.email       = ['a.branzeanu@datarockets.com', 'sebastian.deluca@mejuri.com']
  s.homepage    = 'https://github.com/mejuri-inc/flowcommerce_spree'
  s.summary     = 'Integration of Spree with Flow API'
  s.description = 'Integration of popular Rails/Spree store framework with e-commerce Flow API'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2.3.0'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md', 'SPREE_FLOW.md']
  s.require_path = 'lib'

  s.add_dependency 'colorize'
  s.add_dependency 'concurrent-ruby', '~> 1.0', '>= 1.1.7'
  s.add_dependency 'flowcommerce'
  s.add_dependency 'flowcommerce-reference'
  s.add_dependency 'oj'
  s.add_dependency 'pg', '~> 0.21'
  s.add_dependency 'request_store'
  s.add_dependency 'spree_backend', '~> 2.3.0'

  s.add_development_dependency 'github_changelog_generator'
end
