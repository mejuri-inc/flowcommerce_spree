# Flow, ActiveMerchant and Spree integration

Integration of Spree with Flow, how it is done.

## Installation

Additional configuration could be adjusted in the gem's initializer. For example, the following file could be created 
in the main application, which would add additional attributes of spree_variants to be imported/exported to flow.io:

```
# ./config/initializers/flowcommerce_spree.rb

FlowcommerceSpree::Config.additional_attributes =
  { spree_variants: { country_of_origin: { import: true, export: :optional },
                      customs_description: { import: true, export: :optional, export_name: 'materials' } } }
```

## Things to take into account

ActiveMerchant is not supporting sessions and orders, natively. If one wants
to maintain sessions and orders in Flow, you have to do it outside the ActiveMerchant
terminology which focuses around purchases, voids and refunds.

Another thing to have in mind is that Spree can't work with ActiveMerchant directly, it has to have
an adapter. Adapter can be "stupid" and light, and can forward all the "heavy lifting" to ActiveMerchant gem
but it can also have all the logic localy.

In http://guides.spreecommerce.org/developer/payments.html at the bottom of the page Spree authors say

"better_spree_paypal_express and spree-adyen are good examples of standalone
custom gateways. No dependency on spree_gateway or activemerchant required."

Reading that we can see this is even considered good approach. For us, this is a possibility
but we consume ActiveMerchatFlow gem.

## ActiveMerchant gem into more detail

https://github.com/flowcommerce/active_merchant

Sopporst stanard public ActiveMerchant actions which are
purchase, authorize, capture, void, store and refund.

It depends on following gems

* flowcommerce   - api calls
* flow-reference - we use currency validations

It is not aware of Spree or any other shopping lib or framework.

### ActiveMerchant::Flow supported actions in detail

* purchase  - shortcut for authorize and then capture
* authorize - authorize the cc and funds.
* capture   - capture the funds
* void      - cancel the transaction
* store     - store credit card (gets credit card flow token)
* refund    - refund the funds

## Spree Implementation in more detail

Not present as standalone gem, yet. I will do that once we agree on implementation details.

From product list to purchase, complete chain v1

1. customer has to prepare data, migrate db and connect to Flow. In general
  * create experiences in Flow console, add tiers, shipping methods, etc.
  * add flow_data (jsonb) fields to this models
    * Spree::Variant - we cache localized product prices
    * Spree::Order   - we cache flow order state details, shipping method
  * create and sync product catalog via rake tasks
1. now site users can browse prooducts and add them to cart.
1. when user comes to shop, FlowSession is created
1. once product is in cart
  * spree order is created and linked to Experience that we get from FlowSession
  * it is captured and synced with flow, realtime
    * we do this all the time because we want to have 100% accurate prices.
      Product prices that are shown in cart come directly from Flow API.
  * in checkout, when customer address is added or shipping method defined,
    all is synced with flow order.
  * when order is complete, we trigger flow-cc-authorize or flow-cc-capture directly
    on Spree::Order object instance. This is good because all gateway actions
    are functions of the order object anyway.
    * flow-cc-authorize or flow-cc-capture use ActiveMerchantFlow to execute this actions
    * ActiveMerchantFlow included flow-reference gem

## What can be better

We need a way to access the order in Rails. Access it after it is created in
controller but before it hits the render.
Current implementation is -> "overload" ApplicationController render
If we detect @spree_order object or debug flags, we react.

* good    - elegant solution, all need code is in one file in few lines of code
* bad     - somehow intrusive, we overload render, somw people will not like that.
* alternatives: gem that allows before_render bethod, call explicitly when needed

## Aditional notes - view and frontend

I see many Spree merchant gems carry frontend code, js, coffe, views etc.
I thing that this is bad practise and that shop frontend has to be 100% customer code.

What I did not see but thing is great idea is to have custom light Flow admin present at

/admin/flow

that will ease the way of working with Flow. Code can be made to be Rails 4 and Rails 5 compatibile.
Part of that is allready done as can be seen here [Flow admin screenshot](https://i.imgur.com/FXbPrwK.png)

By default Flow Admin (on /admin/flow) is anybody that is Spree admin.

This way we provide good frontend info, some integration notes in realtime as opposed to running
rake tests to check for integrity of Flow integration.
