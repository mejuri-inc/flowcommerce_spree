# Changelog

## [v0.0.6](https://github.com/mejuri-inc/flowcommerce_spree/tree/v0.0.6) (2021-04-13)

[Full Changelog](https://github.com/mejuri-inc/flowcommerce_spree/compare/v0.0.5...v0.0.6)

**Merged pull requests:**

- \[DL-67\] Small change on current\_zone\_loader module to only load active zones for Flow [\#39](https://github.com/mejuri-inc/flowcommerce_spree/pull/39) ([sebastiandl](https://github.com/sebastiandl))

## [v0.0.5](https://github.com/mejuri-inc/flowcommerce_spree/tree/v0.0.5) (2021-04-07)

[Full Changelog](https://github.com/mejuri-inc/flowcommerce_spree/compare/v0.0.4...v0.0.5)

**Merged pull requests:**

- Flow Phase 4 release [\#38](https://github.com/mejuri-inc/flowcommerce_spree/pull/38) ([sebastiandl](https://github.com/sebastiandl))
- \[DL-276\] Adding charge\_default and lower\_boundary to the shipping FlowIo calculator [\#37](https://github.com/mejuri-inc/flowcommerce_spree/pull/37) ([sebastiandl](https://github.com/sebastiandl))
- \[DL-80\] CardAuthorizationUpsertedV2 specs [\#36](https://github.com/mejuri-inc/flowcommerce_spree/pull/36) ([texpert](https://github.com/texpert))
- \[DL-255\] Small code improvement to avoid synchronization of products when country\_of\_origin is not present [\#35](https://github.com/mejuri-inc/flowcommerce_spree/pull/35) ([sebastiandl](https://github.com/sebastiandl))
- \[DL-80\] Capture\_upserted\_v2 webhook event handler specs and polishing [\#34](https://github.com/mejuri-inc/flowcommerce_spree/pull/34) ([texpert](https://github.com/texpert))
- \[NOTICKET\] Removing code related to leftovers of default\_request\_ip\_address Spree preference [\#33](https://github.com/mejuri-inc/flowcommerce_spree/pull/33) ([sebastiandl](https://github.com/sebastiandl))
- \[DL-77\] Webhooks security [\#31](https://github.com/mejuri-inc/flowcommerce_spree/pull/31) ([texpert](https://github.com/texpert))
- \[DL-72\] Adding some texts within Order's side bar and order's prices to link the user to Flow [\#29](https://github.com/mejuri-inc/flowcommerce_spree/pull/29) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-4443\] Adding flow\_order? validation method that will help identifying if order is associated to flow. [\#28](https://github.com/mejuri-inc/flowcommerce_spree/pull/28) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-4931\] Add test coverage to OrderSync, OrderUpdater, code cleanup [\#27](https://github.com/mejuri-inc/flowcommerce_spree/pull/27) ([texpert](https://github.com/texpert))

## [v0.0.4](https://github.com/mejuri-inc/flowcommerce_spree/tree/v0.0.4) (2021-03-16)

[Full Changelog](https://github.com/mejuri-inc/flowcommerce_spree/compare/v0.0.3...v0.0.4)

**Closed issues:**

- Refactor Spree::Order.sync\_to\_flow\_io to avoid possible exceptions rolling back the AR transactions [\#23](https://github.com/mejuri-inc/flowcommerce_spree/issues/23)

**Merged pull requests:**

- Flow Phase 3 release [\#30](https://github.com/mejuri-inc/flowcommerce_spree/pull/30) ([texpert](https://github.com/texpert))
- \[TEC-4525\] Create refund method for flow.io gateway [\#25](https://github.com/mejuri-inc/flowcommerce_spree/pull/25) ([texpert](https://github.com/texpert))
- \[TEC-3477\] Localized order details for Spree Admin, payments mapping,  OrderUpdater service, refunds [\#20](https://github.com/mejuri-inc/flowcommerce_spree/pull/20) ([texpert](https://github.com/texpert))
- \[NO-TICKET\] defauling FLOW\_TOKEN environment variable to avoid errors [\#19](https://github.com/mejuri-inc/flowcommerce_spree/pull/19) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-3823\] flow endpoint for purchase validations [\#5](https://github.com/mejuri-inc/flowcommerce_spree/pull/5) ([texpert](https://github.com/texpert))

## [v0.0.3](https://github.com/mejuri-inc/flowcommerce_spree/tree/v0.0.3) (2021-02-22)

[Full Changelog](https://github.com/mejuri-inc/flowcommerce_spree/compare/v0.0.2...v0.0.3)

**Merged pull requests:**

- \[TEC-4453\] Adding Flow IO Shipping calcualtor and renaming tax calculator to match naming convention [\#18](https://github.com/mejuri-inc/flowcommerce_spree/pull/18) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-3473\] \[TEC-3791\] \[TEC-4297\] Transition to checkout page, capture payments, tax calculator [\#16](https://github.com/mejuri-inc/flowcommerce_spree/pull/16) ([texpert](https://github.com/texpert))

## [v0.0.2](https://github.com/mejuri-inc/flowcommerce_spree/tree/v0.0.2) (2021-02-18)

[Full Changelog](https://github.com/mejuri-inc/flowcommerce_spree/compare/v0.0.1...v0.0.2)

**Merged pull requests:**

- \[TEC-4792\] Configuring price\_range to return min/max only [\#21](https://github.com/mejuri-inc/flowcommerce_spree/pull/21) ([sebastiandl](https://github.com/sebastiandl))

## [v0.0.1](https://github.com/mejuri-inc/flowcommerce_spree/tree/v0.0.1) (2021-02-03)

[Full Changelog](https://github.com/mejuri-inc/flowcommerce_spree/compare/8376622c8175de74c6b30ae88b42a35b34b64598...v0.0.1)

**Merged pull requests:**

- \[NOTICKET\] Prepare the v0.0.1 release [\#15](https://github.com/mejuri-inc/flowcommerce_spree/pull/15) ([texpert](https://github.com/texpert))
- Fix the use of bundler by GitHub Actions and adding gemspec to the Gemfile [\#14](https://github.com/mejuri-inc/flowcommerce_spree/pull/14) ([texpert](https://github.com/texpert))
- \[TEC-4696\] GitHub check fix [\#11](https://github.com/mejuri-inc/flowcommerce_spree/pull/11) ([sebastiandl](https://github.com/sebastiandl))
- \[NO-TICKET\] configuring dotenvs to automatically load envs from env files [\#10](https://github.com/mejuri-inc/flowcommerce_spree/pull/10) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-4696\] GitHub action configs [\#9](https://github.com/mejuri-inc/flowcommerce_spree/pull/9) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-4667\] product variant model specs [\#8](https://github.com/mejuri-inc/flowcommerce_spree/pull/8) ([sebastiandl](https://github.com/sebastiandl))
- \[TEC-4657\] Adding basic rspec configuration along with some specs for currentZoneLoader [\#7](https://github.com/mejuri-inc/flowcommerce_spree/pull/7) ([sebastiandl](https://github.com/sebastiandl))
- Experience, products and order localizations sync by rake tasks and webhooks [\#4](https://github.com/mejuri-inc/flowcommerce_spree/pull/4) ([texpert](https://github.com/texpert))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
