<img src="https://i.imgur.com/tov8bTw.png" alt="flowcommerce_spree" style="float:right">

# Flow.io < - > Spree adapter

All flowcommerce_spree code is located in the ./app and ./lib folders.

## Installation
- Add the gem to main application's Gemfile:

    ```
    gem 'flowcommerce_spree', git: 'https://github.com/mejuri-inc/flowcommerce_spree'
    ```

- If the main application's Rails version is less than 4.2, add also  to main application's Gemfile the `activerecord
-postgres-json` gem (the mejuri-inc fork allows using a recent Rake version:

    ```
    gem 'activerecord-postgres-json', git: 'https://github.com/mejuri-inc/activerecord-postgres-json'
    ```
 

- Run `bundle install`.

- Define this additional ENV variables. You will find them in 
  [Flow console](https://console.flow.io/org_account_name/organization/integrations):

    ```
    FLOW_TOKEN='SUPERsecretTOKEN' # API_KEY
    FLOW_ORGANIZATION='spree-app-sandbox'
    FLOW_BASE_COUNTRY='usa'
    ```

- The only piece of code that is needed to enable payments with the FlowCommerce engine

    ```
      # config/application.rb
      config.after_initialize do |app|
        # init Flow payments as an option
        app.config.spree.payment_methods << Spree::Gateway::Flow
      end
    ```

- To see and optionally invoke the list of FlowCommerce tasks, run `bundle exec rake flowcommerce_spree:list_tasks
`. Any task from the list could be invoked, typing at the `Type the task number to be invoked:` prompt the task
 number, or from a terminal prompt, in the main application's root folder,  running `bundle exec rake {task_name}` 
 
- Run the `flowcommerce_spree:install:migrations` task to copy the DB migrations' file into the main application's
 `db/migrate` folder. 

- Run `bundle exec rake db:migrate SCOPE=flowcommerce_spree
` from a terminal prompt. This will add an `meta` jsonb column to the Spree::CreditCard, Spree::Product, 
  Spree::Variant, Spree::Order, Spree::Promotion models' DB tables, if there is not yet such a column defined.

- If the main application's Rails version is less than 4.2, add the JSON serializer for the `meta` column to the
 affected models' decorators (Spree::CreditCard, Spree::Product, Spree::Variant, Spree::Order, Spree::Promotion models):
  
  `serialize :flow_data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)`
 

## FlowcommerceSpree::Api module

This is a legacy module using the `curl` gem for making direct calls to flow.io API. It will be refactored out in 
future versions of the gem in favor of using the official flow.io API client from the `flowcommerce` gem.

### FlowcommerceSpree::ExperienceService

Responsible for selecting current experience. You have to define available experiences in flow console.

### FlowcommerceSpree::OrderSync

Maintain and synchronizes Spree::Order with Flow API.

### FlowcommerceSpree::Session

Every shop user has a session. This class helps in creating and maintaining session with Flow.

### Decorators

Decorators are used extensively across the gem to modify or add behaviour of several Spree classes and modules. To 
properly deal with the precedence in the Ruby ancestor chain, the `class_eval`, `include` and `prepend` methods are 
being used, depending on the level of modification.

### Spree::Flow::Gateway

Adapter for Spree, that allows using [Flow.io](https://www.flow.io) as payment gateway. Flow is PCI compliant payment processor.

## Gem Maintenance

### RubyGems credentials

Ensure you have the RubyGems credentials located in the `~/.gem/credentials` file.

### Adding a gem owner

```
gem owner flowcommerce_spree -a sebastian.deluca@mejuri.com
```

### Building a new gem version

Adjust the new gem version number in the `lib/flowcommerce_spree/version.rb` file. It is used when building the gem 
by the following command:

```
gem build flowcommerce_spree.gemspec
```

Asuming the version was set to `0.0.1`, a `flowcommerce_spree-0.0.1.gem` will be generated at the root of the app 
(repo).

### Pushing a new gem release to RubyGems

```
gem push flowcommerce_spree-0.0.1.gem # don't forget to specify the correct version number
```
