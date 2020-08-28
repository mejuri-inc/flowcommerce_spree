<img align="right" src="http://i.imgur.com/tov8bTw.png">

# Flow.io < - > Spree adapter

All flow libs are located in ./app/flow folder with exception of two controllers
ApplicationController and FlowController that are present in ./app/controllers folder.


## Instalation
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

- Define this additional ENV variables. You will find them in [Flow console](https://console.flow.io):

    ```
    FLOW_API_KEY='SUPERsecretTOKEN'
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
` from a terminal prompt. This will add a `flow_data` jsonb column to the Spree::CreditCard, Spree::Product, Spree::Variant, Spree::Order, Spree::Promotion models' DB tables.

- If the main application's Rails version is less than 4.2, add the JSON serializer for the `flow_data` column to the
 affected models' decorators (Spree
                                                                                           ::CreditCard, Spree::Product, Spree::Variant, Spree::Order, Spree::Promotion models):
  
  `serialize :flow_data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)`
 


## Flow API specific

Classes that begin with Flow are responsible for comunicating with flow API.

### Flow

Helper class that offeres low level flow api access and few helper methods.

### Flow::ExperienceService

Responsible for selecting current experience. You have to define available experiences in flow console.

### Flow::Order

Maintain and synchronizes Spree::Order with Flow API.

### Flow::Session

Every shop user has a session. This class helps in creating and maintaining session with Flow.

## Decorators

Decorators are found in ./app/flow/decorators folders and they decorate Spree models with Flow specific methods.

All methods are prefixed with ```flow_```.

## Helper lib

### Spree::Flow::Gateway

Adapter for Spree, that allows using [Flow.io](https://www.flow.io) as payment gateway. Flow is PCI compliant payment processor.
