# frozen_string_literal: true

class CSVUploader
  def initialize(file)
    timestamp     = Time.current.strftime('%Y%m%d%H%M%S')
    @filename     = "#{timestamp}_#{file.original_filename}"
    @file_content = CSV.parse(file.read)
  end

  def self.download_url(file_path, filename); end
end
