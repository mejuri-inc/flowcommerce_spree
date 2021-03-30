Deface::Override.new(
  virtual_path: 'spree/admin/shared/_order_tabs',
  name: 'spree_admin_order_additional_information_flow_message',
  insert_top: '.additional-info',
  text: '
    <% if FlowcommerceSpree::ORGANIZATION.present? && @order.flow_order.present? %>
      <div style="text-align: center">
        <%= link_to "See Flow Order",
                    "https://console.flow.io/#{FlowcommerceSpree::ORGANIZATION}/orders/#{@order.number}",
                    target: "_blank", class: "button" %>
      </div>
    <% end %>'
)
