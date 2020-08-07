require 'flowcommerce'
require 'thread/pool'
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

  # uploads catalog to Flow API
  # using local Spree database
  # run like 'rake flow:upload_catalog[:force]'
  # if you want to force update all products
  desc 'Upload catalog'
  task upload_catalog: :environment do |t|
    # do reqests in paralel
    # thread_pool  = Thread.pool(5)
    update_sum   = 0
    total_sum    = 0
    current_page = 0
    variants     = []

    while current_page == 0 || variants.length > 0
      current_page += 1
      variants = Spree::Variant.order('updated_at desc').page(current_page).per(100).all

      variants.each_with_index do |variant, i|
        total_sum    += 1

        # multiprocess upload
        # thread_pool.process do
          # skip if sync not needed
        result = variant.flow_sync_product

        next $stdout.print "\nVariant #{variant.sku} is synced, no need to update".green unless result

        if result.is_a?(Hash) && result[:error]
          $stdout.print "\nError uploading #{variant.sku}. Reason: #{result[:error]}".red
        else
          update_sum += 1
          $stdout.print "\n#{variant.sku}: #{variant.product.name} (#{variant.price} #{variant.cost_currency})"
        end
        # end
      end
    end

    # thread_pool.shutdown

    needed_update = (update_sum == 0 ? 'none' : update_sum).to_s.green
    puts "\nFor total of #{total_sum.to_s.blue} products, #{needed_update} needed update"
    t.reenable
  end

  desc 'Check if ENV vars, center and tier per experience is set'
  task check: :environment do |t|
    puts 'Environment check'
    required_env_vars = %w[FLOW_API_KEY FLOW_ORGANIZATION FLOW_BASE_COUNTRY]
    required_env_vars.each { |el| puts " ENV: #{el} - #{ENV[el].present? ? 'present'.green : 'MISSING'.red} " }

    puts 'Experiences:'
    puts " Getting experiences for flow org: #{Flow::ORGANIZATION}"
    client      = FlowCommerce.instance
    experiences = client.experiences.get(Flow::ORGANIZATION)
    puts " Got %d experiences - #{experiences.map(&:country).join(', ')}".green % experiences.length

    # create default experience unless one exists
    puts 'Centers:'
    center_name     = 'default'
    current_centers = client.centers.get(Flow::ORGANIZATION).map(&:key)
    if current_centers.include?(center_name)
      puts " Default center: #{'present'.green}"
    else
      Flow.api :put, "/:organization/centers/#{center_name}", {},
               {'key': center_name,
                'address': { 'contact': { 'name': { 'first': 'Kinto',
                                                    'last':'Doe' },
                                          'company': Flow::ORGANIZATION,
                                          'email': 'dcone@test.flow.io',
                                          'phone': '1-555-444-0001' },
                             'location': { 'streets': ['88 East Broad Street'],
                                           'city': 'Columbus',
                                           'province': 'OH',
                                           'postal': '43215',
                                           'country': Flow::BASE_COUNTRY } },
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
      exp_tiers = FlowCommerce.instance.tiers.get(Flow::ORGANIZATION, experience: exp.key)
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
    ratecards = client.ratecards.get(Flow::ORGANIZATION).each do |rc|
      rc.origination_zones.each do |oz|
        data = Flow.api :post, ratecard_estimates_path, {}, { origin: oz.country, destination: origins.last || 'MDA' }

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

  desc 'Sync localized catalog items'
  task sync_localized_items: :environment do |t|
    # we have to log start, so that another process does not start while this one is running
    next unless FlowApiRefresh.needs_refresh?

    FlowApiRefresh.log_refresh!

    puts 'Sync needed, running ...'.yellow

    # mark that sync happend
    system 'curl -fsS --retry 3 https://hchk.io/93912c0e-65cd-4f5b-a912-8983448f370b > /dev/null'

    total = 0

    experiences = FlowCommerce.instance.experiences.get(Flow::ORGANIZATION)

    experiences.each do |experience|
      page_size  = 100
      offset     = 0
      items      = []

      while offset == 0 || items.length == 100
        # show current list size
        puts "\nGetting items: #{experience.key.green}, rows #{offset} - #{offset + page_size}"

        items = FlowCommerce.instance.experiences.get_items(
          Flow::ORGANIZATION, experience: experience.key, limit: page_size, offset: offset
        )

        offset += page_size

        items.each do |item|
          total += 1
          sku        = "p#{item.number}"
          variant    = Spree::Variant.find_by(id: sku)
          next unless variant

          # if item is not included, mark it in product as excluded
          # regardles if excluded or restricted
          unless item.local.status.value == 'included'
            print "[#{item.local.status.value.red}]:"
            if (product = variant.product)
              product.flow_data["#{experience.key}.excluded"] = 1
              product.update_column(:flow_data, product.flow_data.to_json)
            end
          end

          variant.flow_import_item(item)

          print "#{sku}, "
        end
      end
    end

    # Log sync end time
    FlowApiRefresh.log_refresh! true

    puts "Finished with total of #{total.to_s.green} rows."

    t.reenable
  end

  # checks existance of every item in local product catalog
  # remove product from flow unless exists localy
  desc 'Remove unused items from flow catalog'
  task clean_catalog: :environment do |t|

    page_size  = 100
    offset     = 0
    items      = []

    thread_pool = Thread.pool(5)

    while offset == 0 || items.length == 100
      items = Flow.api :get, '/:organization/catalog/items', limit: page_size, offset: offset
      offset += page_size

      items.each do |item|
        sku = item['number']

        do_remove = false

        # sku has to be an integer
        do_remove = true if sku.to_i == 0 || sku.to_i.to_s != sku

        # remove if variant not found
        do_remove ||= true unless Spree::Variant.find_by(id: sku.to_i)

        next unless do_remove

        thread_pool.process do
          Flow.api :delete, "/:organization/catalog/items/#{sku}"
          $stdout.puts "Removed item: #{sku.red}"
        end
      end
    end

    thread_pool.shutdown
    t.reenable
  end

  # remove all the products from flow.io
  desc 'Purge Product Catalog on flow.io'
  task purge_catalog: :environment do |t|

    page_size  = 100
    offset     = 0
    items      = []

    thread_pool = Thread.pool(5)

    while offset == 0 || items.length == 100
      items = Flow.api :get, '/:organization/catalog/items', limit: page_size, offset: offset
      offset += page_size

      items.each do |item|
        sku = item['number']

        thread_pool.process do
          Flow.api :delete, "/:organization/catalog/items/#{sku}"
          $stdout.puts "Removed item: #{sku.red}"
        end
      end
    end

    thread_pool.shutdown
    Spree::Variant.flow_truncate
    t.reenable
  end

  # creates needed fields in DB for Flow to work
  desc 'Run flowcommerce_spree DB migrations'
  task migrate: :environment do |t|
    Rake::Task['db:migrate'].invoke('SCOPE=flowcommerce_spree')
    t.reenable
  end

  desc 'Pretty print flow_data of last updated product variant'
  task sync_check: :environment do |t|
    data = Spree::Variant.order('updated_at desc').first.flow_data
    puts JSON.pretty_generate(data).gsub(/"(\w+)":/) { "\"#{$1.yellow}\":" }
    t.reenable
  end

  desc 'Exit list_tasks'
  task exit: :environment do
    @exit = true
  end
end
