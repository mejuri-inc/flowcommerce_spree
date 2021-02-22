<img src="https://i.imgur.com/tov8bTw.png" alt="flowcommerce_spree" style="float:right">

# Flow.io < - > Spree adapter

All flowcommerce_spree code is located in the ./app and ./lib folders.

## Installation
- Add the gem to main application's Gemfile:

    ```
    gem 'flowcommerce_spree', git: 'https://github.com/mejuri-inc/flowcommerce_spree'
    ```

- If the main application's Rails version is less than 4.2, add also to main application's Gemfile the `activerecord
-postgres-json` gem (at least version 0.2.3):

    ```
    gem 'activerecord-postgres-json', '>= 0.2.3'
    ```

- Run `bundle install`.

- Define this additional ENV variables. You will find all of them, except FLOW_MOUNT_PATH in 
  [Flow console](https://console.flow.io/org_account_name/organization/integrations):

    ```
    FLOW_TOKEN='SUPERsecretTOKEN' # API_KEY
    FLOW_ORGANIZATION='spree-app-sandbox'
    FLOW_BASE_COUNTRY='usa'
    # The path to which the FlowcommerceSpree engine will be mounted (default, if this variable is missing, will be the 
    # '/flow' path)
    FLOW_MOUNT_PATH='/flow' 
    ```

- To enable payments with the FlowCommerce engine, the payment method `flow.io` with `Spree::Gateway::FlowIo` should be 
  added in the Spree Admin. This payment method is automatically registered in the gem in an after_initialize Rails 
  engine callback:

    ```
      # lib/flowcommerce_spree/engine.rb
      config.after_initialize do |app|
        # init Flow payments as an option
        app.config.spree.payment_methods << Spree::Gateway::FlowIo
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

### Spree::Gateway::FlowIo

Adapter for Spree, that allows using [Flow.io](https://www.flow.io) as payment gateway. Flow is PCI compliant payment processor.

## Gem Maintenance

### Preparing a release

Merge all the pull requests that should make it into the new release into the `main` branch, then checkout and pull the 
branch and run the `github_changelog_generator`, specifying the new version as a `--future-release` cli parameter:

```
git checkout main
git pull

github_changelog_generator -u mejuri-inc -p flowcommerce_spree --future-release v0.0.2
```

Then add the changes to `git`, commit and push the `Preparing the new release` commit directly into the `main` branch:

```
git add .
git commit -m 'Preparing the new v0.0.2 release'
git push
```

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
