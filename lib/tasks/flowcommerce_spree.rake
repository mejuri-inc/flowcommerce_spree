require 'flowcommerce'
require 'digest/sha1'
require 'colorize'

namespace :flowcommerce_spree do
  desc 'Listing and possible invocation of all the Flow tasks'
  task :list_tasks do |t|
    task_list = `#{'rake -T | grep flowcommerce_spree'}`.split($/)
    @exit = false
    puts "Executing: #{t}", ''

    loop do
      puts 'Flowcommerce tasks:'
      task_list.each_with_index do |task, index|
        puts " %3d. #{task}" % (index + 1)
      end

      print "\nType the task number to be invoked: "
      task_number = $stdin.gets.to_i

      if (1..task_list.size).cover?(task_number)
        selected_task_name = task_list[task_number - 1].to_s.split(/\s+/)[1]
        puts "\nRunning: #{selected_task_name}"
        Rake::Task[selected_task_name].invoke
        puts
      else
        puts "Unknown task number: #{task_number}".red, ''
      end

      break if @exit
    end
  end

  # uploads catalog to Flow API using local Spree database
  desc 'Upload catalog'
  task upload_catalog: :environment do |t|
    $update_sum   = 0
    total_sum    = 0
    current_page = 0
    variants     = []
    promises = []
    thread_pool = Concurrent::FixedThreadPool.new(5)

    while current_page == 0 || variants.length > 0
      current_page += 1
      variants = Spree::Variant.order('updated_at desc').page(current_page).per(100).all

      variants.each do |variant|
        total_sum    += 1

        # multithread upload - perform requests in parallel
        promises << Concurrent::Promises.future_on(thread_pool, variant) do |variant|
          ActiveRecord::Base.connection_pool.with_connection do
            result = variant.sync_product_to_flow

            # skip if sync not needed
            next $stdout.print "\nVariant #{variant.sku} is synced, no need to update".green unless result

            if result.is_a?(Hash) && result[:error]
              $stdout.print "\nError uploading #{variant.sku}. Reason: #{result[:error]}".red
            else
              $update_sum += 1
              $stdout.print "\n#{variant.sku}: #{variant.product.name} (#{variant.price} #{variant.cost_currency})"
            end
          end
        end
      end
    end

    Concurrent::Promises.zip(*promises).value!
    thread_pool.shutdown
    thread_pool.wait_for_termination

    needed_update = ($update_sum == 0 ? 'none' : $update_sum).to_s.green
    puts "\nFor total of #{total_sum.to_s.blue} products, #{needed_update} needed update"
    $update_sum = nil
    t.reenable
  end

  desc 'Check if ENV vars, center and tier per experience is set'
  task check: :environment do |t|
    puts 'Environment check'
    required_env_vars = %w[FLOW_API_KEY FLOW_ORGANIZATION FLOW_BASE_COUNTRY]
    required_env_vars.each { |el| puts " ENV: #{el} - #{ENV[el].present? ? 'present'.green : 'MISSING'.red} " }
    organization = FlowcommerceSpree::ORGANIZATION

    puts 'Experiences:'
    puts " Getting experiences for flow org: #{organization}"
    client      = FlowCommerce.instance
    experiences = client.experiences.get(organization)
    puts " Got %d experiences - #{experiences.map(&:country).join(', ')}".green % experiences.length

    # create default experience unless one exists
    puts 'Centers:'
    center_name     = 'default'
    current_centers = client.centers.get(organization).map(&:key)
    if current_centers.include?(center_name)
      puts " Default center: #{'present'.green}"
    else
      FlowcommerceSpree::Api.run :put, "/:organization/centers/#{center_name}", {},
               {'key': center_name,
                'address': { 'contact': { 'name': { 'first': 'Kinto',
                                                    'last':'Doe' },
                                          'company': organization,
                                          'email': 'dcone@test.flow.io',
                                          'phone': '1-555-444-0001' },
                             'location': { 'streets': ['88 East Broad Street'],
                                           'city': 'Columbus',
                                           'province': 'OH',
                                           'postal': '43215',
                                           'country': FlowcommerceSpree::BASE_COUNTRY } },
                'packaging': [{ 'dimensions': { 'packaging': { 'depth':  { 'value': '9',  'units': 'inch' },
                                                               'length': { 'value': '13', 'units': 'inch' },
                                                               'weight': { 'value': '1',  'units': 'pound' },
                                                               'width':  { 'value': '3',  'units': 'inch' } } },
                                'name': 'Big Box',
                                'number': 'box1' }],
                'name': 'Spree Test',
                'services': [{ 'service': 'dhl-express-worldwide' },
                             { 'service': 'landmark-global' }],
                'schedule': { 'holiday': 'us_bank_holidays',
                              'exception': [{ 'type': 'closed',
                                              'datetime_range': { 'from': '2016-05-05T18:30:00.000Z',
                                                                  'to':   '2016-05-06T18:30:00.000Z' } }],
                              'calendar': 'weekdays',
                              'cutoff': '16:30' },
                'timezone': 'US/Eastern' }
      puts " Default center: #{'created'.blue} (run again)"
    end

    puts 'Tiers:'
    experiences.each do |exp|
      exp_tiers = client.tiers.get(FlowcommerceSpree::ORGANIZATION, experience: exp.key)
      count        = exp_tiers.length
      count_desc   = count == 0 ? '0 (error!)'.red : count.to_s.green
      print " Experience #{exp.key.yellow} has #{count_desc} delivery tiers defined, "

      exp_services = exp_tiers.inject([]) { |total, tier| total.push(*tier.services.map(&:id)) }
      if exp_services.length == 0
        puts 'and no delivery services defined!'.red
      else
        puts "with #{exp_services.length.to_s.green} delivery services defined (#{exp_services.join(', ')})"
      end
    end

    puts 'Database fields (flow_data):'
    [Spree::CreditCard, Spree::Product, Spree::Variant, Spree::Order, Spree::Promotion].each { |klass|
      state = klass.new.respond_to?(:flow_data) ? 'exists'.green : 'not present (run DB migrations)'.red
      puts " #{klass.to_s.ljust(18)} - #{state}"
    }

    puts 'Default store URL:'
    url = Spree::Store.find_by(default:true).url
    puts " Spree::Store.find_by(default:true).url == \"#{url.blue}\" (ensure this is valid and right URL)"

    # rate cards check
    ratecard_estimates_path = '/:organization/ratecard_estimates/summaries'
    origins = []
    errors = []
    ratecards = client.ratecards.get(FlowcommerceSpree::ORGANIZATION).each do |rc|
      rc.origination_zones.each do |oz|
        data = FlowcommerceSpree::Api.run :post, ratecard_estimates_path, {}, { origin: oz.country, destination: origins.last || 'MDA' }

        if data.is_a?(Hash) && data['code'] == 'generic_error'
          errors << { origin: oz.country, messages: data['messages'] }
          next
        elsif data.is_a?(Array) && data.length > 0
          origins << oz.country
        else
          errors << { origin: oz.country, messages: ['Unknown error'] }
        end
      end
    end
    if origins.size > 0
      puts "\nRate cards set, OK:".green
      origins.each_with_index do |origin, index|
        puts " %3d. #{origin}" % (index + 1)
      end
    end
    if errors.size > 0
      puts "\nRate cards errors:".red
      errors.each_with_index do |err, index|
        puts " %3d. Origin = #{err[:origin]}, errors:" % (index + 1)
        err[:messages].each do |m|
          puts "      #{m}".red
        end
      end
    end
    t.reenable
  end

  desc 'Sync experiences and localized product catalog items from Flow.io'
  task sync_localized_items: :environment do |t|
    next t.reenable unless FlowcommerceSpree::ApiRefresh.needs_refresh?

    puts 'Sync needed, running ...'.yellow

    total = FlowcommerceSpree::ImportExperiences.new.run

    puts "Finished with total of #{total.to_s.green} rows."

    t.reenable
  end

  desc 'Force sync (no timeout) experiences and localized product catalog items from Flow.io'
  task sync_localized_items_forced: :environment do |t|
    next t.reenable if FlowcommerceSpree::ApiRefresh.in_progress?

    total = FlowcommerceSpree::ImportExperiences.new.run

    puts "Finished with total of #{total.to_s.green} rows."

    t.reenable
  end

  # checks existence of every item in local product catalog - remove product from flow unless exists locally
  desc 'Remove unused items from flow catalog'
  task clean_flow_catalog: :environment do |t|
    page_size  = 100
    offset     = 0
    items      = []
    promises = []
    thread_pool = Concurrent::FixedThreadPool.new(5)

    while offset == 0 || items.length == 100
      items = FlowcommerceSpree::Api.run :get, '/:organization/catalog/items', limit: page_size, offset: offset
      offset += page_size

      items.each do |item|
        sku = item['number']

        next if Spree::Variant.exists?(sku: sku)

        promises << Concurrent::Promises.future_on(thread_pool, sku) do |number|
          FlowcommerceSpree::Api.run :delete, "/:organization/catalog/items/#{number}"
          $stdout.puts "Removed item: #{number.red}"
        end
      end
    end

    Concurrent::Promises.zip(*promises).value!
    thread_pool.shutdown
    thread_pool.wait_for_termination
    t.reenable
  end

  # remove all the products from flow.io
  desc 'Purge Product Catalog on flow.io'
  task purge_catalog: :environment do |t|
    page_size  = 100
    offset     = 0
    items      = []
    promises = []
    thread_pool = Concurrent::FixedThreadPool.new(5)

    while offset == 0 || items.length == 100
      items = FlowcommerceSpree::Api.run :get, '/:organization/catalog/items', limit: page_size, offset: offset
      offset += page_size

      items.each do |item|
        sku = item['number']

        promises << Concurrent::Promises.future_on(thread_pool, sku) do |sku|
          FlowcommerceSpree::Api.run :delete, "/:organization/catalog/items/#{sku}"
          $stdout.puts "Removed item: #{sku.red}"
        end
      end
    end

    Concurrent::Promises.zip(*promises).value!
    thread_pool.shutdown
    thread_pool.wait_for_termination
    t.reenable
  end

  desc 'Purge flow_data from all the Variants in the DB'
  task purge_flow_data: :environment do |t|
    record_counter = 0
    Spree::Variant.where("meta->>'flow_data' IS NOT NULL").each do |v|
      v.truncate_flow_data
      record_counter +=1
      print '.'
      $stdout.flush
    end
    puts "\nTruncated flow_data on #{record_counter} records"

    t.reenable
  end

  desc 'Exit list_tasks'
  task exit: :environment do
    @exit = true
  end
end
