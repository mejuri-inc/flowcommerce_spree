Deface::Override.new(
  virtual_path: 'spree/admin/prices/index',
  name: 'spree_admin_prices_flow_mesage',
  insert_top: '.no-border-top',
  text: "
  <div class='spree-admin-info' >
    Some prices might not be shown in this list. You can find them <a href='#{"https://console.flow.io/#{ENV['FLOW_ORGANIZATION']}/price-books"}' target='_blank'>here</a>.
  </div>"
)
