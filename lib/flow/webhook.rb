# Flow.io (2017)
# communicates with flow api, responds to webhook events

class Flow::Webhook
  attr_accessor :product
  attr_accessor :variant

  class << self
    def process data, opts={}
      web_hook = new data, opts
      web_hook.process
    end

    def logger
      @@webhook_logger ||= Logger.new logger_path
    end

    def logger_path
      Rails.root.join('log/webhooks.log').to_s
    end

    # read n last lines from log
    def logger_read_lines num=100
      `tail -100 #{logger_path}`.split($/)
    end
  end

  ###

  def initialize(data, opts={})
    @data = data
    @opts = opts
  end

  def process
    @discriminator = @data['discriminator']

    m = 'hook_%s' % @discriminator

    return 'Error: No hook for %s' % @discriminator unless respond_to?(m)
    raise ArgumentError, 'Organization name mismatch for %s' % @data['organization'] if @data['organization'] != Flow::ORGANIZATION

    send(m)
  end

  # hooks

  def hook_localized_item_upserted
    raise ArgumentError, 'number not found' unless @data['number']
    raise ArgumentError, 'local not found' unless @data['local']

    number  = @data['number']
    exp_key = @data['local']['experience']['key']

    # for testing we need ability to inject dependency for variant class
    variant_class = @opts[:variant_class] || Spree::Variant
    @variant      = variant_class.find_by id: number

    unless @variant
      error_message = 'Product variant with number [%s] not found: %s' % [number, @data.to_json]
      # raise Flow::Error.new(error_message)
      return error_message
    end

    @product      = @variant.product
    is_included   = @data['local']['status'] == 'included'

    @product.flow_data['%s.excluded' % exp_key] = is_included ? 0 : 1

    @product.save!

    message = is_included ? 'included in' : 'excluded from'

    'Product id:%s - "%s" (from variant %s) %s experience "%s"' % [@product.id, @product.name, @variant.id, message, exp_key]
  end

  # we should consume only localized_item_upserted
  def hook_subcatalog_item_upserted
    experience = Flow::Experience.get_by_subcatalog_id @data['subcatalog_id']
    return unless experience

    @data['local'] = {
      'experience' => { 'key'=> experience.key },
      'status'     => @data['status']
    }

    hook_localized_item_upserted
  end

  # send en email when order is refunded
  def hook_refund_upserted_v2
    Spree::OrderMailer.refund_complete_email(@data).deliver

    'Email delivered'
  end
end
