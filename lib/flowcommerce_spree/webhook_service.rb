# communicates with flow api, responds to webhook events
module FlowcommerceSpree
  class WebhookService
    attr_accessor :product
    attr_accessor :variant

    def self.process(data, opts={})
      web_hook = new(data, opts)
      web_hook.process
    end

    def initialize(data, opts={})
      @data = data
      @opts = opts
    end

    def process
      org = @data['organization']
      return { error: 'NoMethodError', message: "Organization name mismatch for #{org}" } if org != Flow::ORGANIZATION

      discriminator = @data['discriminator']
      hook_method = "hook_#{discriminator}"

      return { error: 'NoMethodError', message: "No hook for #{discriminator}" } unless respond_to?(hook_method, true)

      __send__(hook_method)
    end

    private

    def hook_experience_upserted
      FlowcommerceSpree::Experience.find_or_initialize_by(key: @data['key']).upsert_data(@data)
    end

    def hook_experience_upserted_v2
      exp = @data['experience']
      FlowcommerceSpree::Experience.find_or_initialize_by(key: exp['key']).upsert_data(exp)
    end

    def hook_local_item_upserted
      local_item = @data['local_item']
      return { error: 'Unprocessable entity', message: 'Local item param missing' } unless local_item

      received_sku = local_item.dig('item', 'number')
      return { error: 'Unprocessable entity', message: 'SKU not param missing' } unless received_sku

      exp_key = local_item.dig('experience', 'key')

      # TODO: Check if this is really necessary
      # for testing we need ability to inject dependency for variant class
      variant_class = @opts[:variant_class] || Spree::Variant
      @variant      = variant_class.find_by(sku: received_sku)

      return { error: 'Unprocessable entity', message: "Variant with sku [#{received_sku}] not found!" } unless @variant

      @variant.exp[exp_key] = {} unless @variant.exp[exp_key]
      variant_experience = @variant.exp[exp_key]
      variant_experience['prices'] = [local_item.dig('pricing', 'price')]
      variant_experience['status'] = local_item['status']

      @variant.update_column(:flow_data, @variant.flow_data.to_json)

      local_item
    end

    # we should consume only localized_item_upserted
    def hook_subcatalog_item_upserted
      experience = FlowcommerceSpree::ExperienceService.get_by_subcatalog_id @data['subcatalog_id']
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
end
