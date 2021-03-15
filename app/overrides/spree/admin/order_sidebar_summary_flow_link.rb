Deface::Override.new(
  virtual_path: 'spree/admin/shared/_order_tabs',
  name: 'spree_admin_order_additional_information_flow_message',
  insert_top: '.additional-info',
  text: '
    <% if FlowcommerceSpree::ORGANIZATION.present? && @order.flow_order.present? %>
      <dt data-hook>Flow Order</dt>
      <dd id="item_total">
        <%= link_to "See order on Flow",
                  "https://console.flow.io/#{FlowcommerceSpree::ORGANIZATION}/orders/#{@order.number}" %>
      </dd>
    <% end %>'
)
