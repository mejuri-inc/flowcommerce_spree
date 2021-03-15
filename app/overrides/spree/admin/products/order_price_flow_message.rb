Deface::Override.new(
  virtual_path: 'spree/admin/prices/index',
  name: 'spree_admin_prices_flow_mesage',
  insert_top: '.no-border-top',
  text: "
  <div style='margin-bottom: 20px;'>
    <h5>
      Some prices might not be shown in this list. You can find them here <a href='#{"https://console.flow.io/#{ENV['FLOW_ORGANIZATION']}/price-books"}'>here</a>.
    </h5>
  </div>"
)
