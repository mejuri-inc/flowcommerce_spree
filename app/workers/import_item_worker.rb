class ImportItemWorker
  include Sidekiq::Worker
  sidekiq_options queue: :flow_io

  def perform(variant)
    ImportItem.run(variant)
  end
end
