Deface::Override.new(
  virtual_path: 'spree/admin/prices/index',
  name: 'spree_admin_prices_flow_mesage',
  insert_top: '.no-border-top',
  text: "
  <div class='spree-admin-info' >
    To check localized pricing, please click <a href='#{"https://console.flow.io/#{ENV['FLOW_ORGANIZATION']}/price-books"}' target='_blank'>here</a>.
  </div>"
)
