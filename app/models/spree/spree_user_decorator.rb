# frozen_string_literal: true

# added flow specific methods to Spree.user_class
# which is for Spree in same time
# - user object (for admins as well)
# - customer object

Spree.user_class.class_eval do
  def flow_number
    return unless id

    token = ENV.fetch('ENCRYPTION_KEY')
    "su-#{Digest::SHA1.hexdigest(format('%d-%s', id, token))}"
  end
end
