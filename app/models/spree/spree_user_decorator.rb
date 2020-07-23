# added flow specific methods to Spree.user_class
# which is for Spree in same time
# - user object (for admins as well)
# - customer object

Spree.user_class.class_eval do
  def flow_number
    return unless id

    token = ENV.fetch('SECRET_TOKEN')
    'su-%s' % Digest::SHA1.hexdigest('%d-%s' % [id, token])
  end
end
