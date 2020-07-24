<img align="right" src="http://i.imgur.com/tov8bTw.png">

# Flow.io < - > Spree adapter

All flow libs are located in ./app/flow folder with exception of two controllers
ApplicationController and FlowController that are present in ./app/controllers folder.


## Instalation

Define this additional ENV variables. You will find them in [Flow console](https://console.flow.io)

```
FLOW_API_KEY='SUPERsecretTOKEN'
FLOW_ORGANIZATION='spree-app-sandbox'
FLOW_BASE_COUNTRY='usa'
```

In ```./config/application.rb``` this is the only peace of code that is needed to
init complete flow app

```
  config.to_prepare do
    # add all flow libs
    overload = Dir.glob('./app/flow/**/*.rb')
    overload.reverse.each { |c| require(c) }
  end

  config.after_initialize do |app|
    # init Flow payments as an option
    app.config.spree.payment_methods << Spree::Gateway::Flow
  end
```

in ./config/application.rb to enable payments with Flow.

## Flow API specific

Classes that begin with Flow are responsible for comunicating with flow API.

### Flow

Helper class that offeres low level flow api access and few helper methods.

### Flow::Experience

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
