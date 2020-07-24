require 'flowcommerce'
require 'thread/pool'
require 'digest/sha1'
require 'colorize'
require 'awesome_print'

desc 'Listing and possible invocation of all the Flow tasks'
task :flow do |t|
  tasks = `#{'rake -T | grep flow'}`.split($/)

  puts "Executing: #{t} (#{tasks[0].partition('# ').last}):", ''

  tasks.each_with_index do |task, index|
    puts ' %3d. %s' % [index + 1, task]
  end

  print "\nType the task number to be invoked: "
  task_number = $stdin.gets.to_i

  if (1..tasks.size).cover?(task_number)
    if task_number == 1
      puts 'The app:flow task was currently being run'.green
    else
      task = tasks[task_number - 1].to_s.split(/\s+/)[1]
      puts 'Executing: %s' % task
      Rake::Task[task].invoke
    end
  else
    puts "Unknown task number: #{task_number}".red
  end
end

namespace :flow do
  # uploads catalog to Flow API
  # using local Spree database
  # run like 'rake flow:upload_catalog[:force]'
  # if you want to force update all products
  desc 'Upload catalog'
  task :upload_catalog => :environment do |t|
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
          if variant.flow_sync_product
            update_sum += 1
            $stdout.print "\n%s: %s (%s %s)" % [variant.id.to_s, variant.product.name, variant.price, variant.cost_currency]
          else
            $stdout.print '.'
          end
        # end
      end
    end

    # thread_pool.shutdown

    puts "\nFor total of %s products, %s needed update" % [total_sum.to_s.blue, (update_sum == 0 ? 'none' : update_sum).to_s.green]
  end

  desc 'Check if ENV vars, center and tier per experience is set'
  task check: :environment do
    puts 'Environment check'
    required_env_vars = %w[FLOW_API_KEY FLOW_ORGANIZATION FLOW_BASE_COUNTRY]
    required_env_vars.each { |el| puts ' ENV: %s - %s ' % [el, ENV[el].present? ? 'present'.green : 'MISSING'.red]  }

    # experiences
    puts 'Experiences:'
    puts ' Getting experiences for flow org: %s' % Flow::ORGANIZATION
    client      = FlowCommerce.instance
    experiences = client.experiences.get(Flow::ORGANIZATION)
    puts ' Got %d experiences - %s'.green % [experiences.length, experiences.map(&:country).join(', ')]

    # create default experience unless one exists
    puts 'Centers:'
    center_name     = 'default'
    current_centers = client.centers.get(Flow::ORGANIZATION).map(&:key)
    if current_centers.include?(center_name)
      puts ' Default center: %s' % 'present'.green
    else
      Flow.api :put, '/:organization/centers/%s' % center_name, {}, {'key':center_name,
                                                                     'address':{'contact':{'name':{'first':'Kinto',
                                                                                                   'last':'Doe'},
                                                                                           'company':'XYZ
                                                                                           Corporation, Inc','email':'dcone@test.flow.io','phone':'1-555-444-0001'},'location':{'streets':['88 East Broad Street'],'city':'Columbus','province':'OH','postal':'43215','country':'USA'}},'packaging':[{'dimensions':{'packaging':{'depth':{'value':'9','units':'inch'},'length':{'value':'13','units':'inch'},'weight':{'value':'1','units':'pound'},'width':{'value':'3','units':'inch'}}},'name':'Big Box','number':'box1'}],'name':'Spree Test','services':[{'service':'dhl-express-worldwide'},{'service':'landmark-global'}],'schedule':{'holiday':'us_bank_holidays','exception':[{'type':'closed','datetime_range':{'from':'2016-05-05T18:30:00.000Z','to':'2016-05-06T18:30:00.000Z'}}],'calendar':'weekdays','cutoff':'16:30'},'timezone':'US/Eastern'}
      puts ' Default center: %s (run again)' % 'created'.blue
    end

    # tiers
    puts 'Tiers:'
    experiences.each do |exp|
      exp_tiers = FlowCommerce.instance.tiers.get(Flow::ORGANIZATION, experience: exp.key)
      count        = exp_tiers.length
      count_desc   = count == 0 ? '0 (error!)'.red : count.to_s.green
      print ' Experience %s has %s devivery tiers defined, ' % [exp.key.yellow, count_desc]

      exp_services = exp_tiers.inject([]) { |total, tier| total.push(*tier.services.map(&:id)) }
      if exp_services.length == 0
        puts 'and no delivery services defined!'.red
      else
        puts 'with %s devlivery services defined (%s)' % [exp_services.length.to_s.green, exp_services.join(', ')]
      end
    end

    # database fields
    puts 'Database field (flow_data)'
    for klass in [Spree::CreditCard, Spree::Product, Spree::Variant, Spree::Order, Spree::Promotion]
      state = klass.new.respond_to?(:flow_data) ? 'exists'.green : 'not present (run rake flow:migrate)'.red
      puts ' %s - %s' % [klass.to_s.ljust(18), state]
    end

    # default URL
    puts 'Default store URL:'
    url = Spree::Store.find_by(default:true).url
    puts ' Spree::Store.find_by(default:true).url == "%s" (ensure this is valid and right URL)' % url.blue

    # rate cards
    puts 'Rate cards (checking shipping from Canada to France):'
    data = Flow.api :post, '/:organization/ratecard_estimates/summaries', {},
                    { origin: 'Canada', destination: 'France' }
    if data.is_a?(Array) && data.length > 0
      puts ' Rate cards set, OK'.green
    else
      puts ' error!'.red
      ap data
    end
  end

  desc 'Sync localized catalog items'
  task :sync_localized_items => :environment do |t|
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
        puts "\nGetting items: %s, rows %s - %s" % [experience.key.green, offset, offset + page_size]

        items = FlowCommerce.instance.experiences.get_items Flow::ORGANIZATION, experience: experience.key, limit: page_size, offset: offset

        offset += page_size

        items.each do |item|
          total += 1
          sku        = item.number.downcase
          variant    = Spree::Variant.find_by id: sku.split('-').last.to_i
          next unless variant

          # if item is not included, mark it in product as excluded
          # regardles if excluded or restricted
          unless item.local.status.value == 'included'
            print '[%s]:' % item.local.status.value.red
            if product = variant.product
              product.flow_data['%s.excluded' % experience.key] = 1
              product.update_column :flow_data, product.flow_data.dup
            end
          end

          variant.flow_import_item item

          print '%s, ' % sku
        end
      end
    end

    # Log sync end time
    FlowApiRefresh.log_refresh! true

    puts 'Finished with total of %s rows.' % total.to_s.green
  end

  # checks existance of every item in local product catalog
  # remove product from flow unless exists localy
  desc 'Remove unused items from flow catalog'
  task clean_catalog: :environment do

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
        do_remove ||= true if !Spree::Variant.find_by(id: sku.to_i)

        next unless do_remove

        thread_pool.process do
          Flow.api :delete, '/:organization/catalog/items/%s' % sku
          $stdout.puts 'Removed item: %s' % sku.red
        end
      end
    end

    thread_pool.shutdown
  end

  # creates needed fields in DB for Flow to work
  desc 'Ensure we have DB prepared for flow'
  task :migrate => :environment do |t|
    migrate = []
    migrate.push [:spree_products,     :flow_data, :jsonb, default: {}]
    migrate.push [:spree_variants,     :flow_data, :jsonb, default: {}]
    migrate.push [:spree_orders,       :flow_data, :jsonb, default: {}]
    migrate.push [:spree_promotions,   :flow_data, :jsonb, default: {}]

    migrate.each do |table, field, type, opts={}|
      klass = table.to_s.sub('spree_','spree/').classify.constantize

      if klass.new.respond_to?(field)
        puts 'Field %s in table %s exists'.green % [field, table]
      else
        ActiveRecord::Migration.add_column table, field, type, opts
        puts 'Field %s in table %s added'.blue % [field, table]
      end
    end
  end

  desc 'Pretty print flow_data of last updated product variant'
  task :sync_check => :environment do |t|
    data = Spree::Variant.order('updated_at desc').first.flow_data
    puts JSON.pretty_generate(data).gsub(/"(\w+)":/) { '"%s":' % $1.yellow }
  end
end

