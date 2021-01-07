# frozen_string_literal: true

# simple class to build scv files

# csv = CsvWriter.new
# csv.add a: 1, b: 'a', c: '"a'
# csv.add a: ',', b: 'foo, bar'
# csv.to_s

class SimpleCsvWriter
  def initialize(delimiter: nil)
    @data      = []
    @delimiter = delimiter || "\t"
  end

  # add hash or list
  def add(data)
    list = if data.class == Hash
             @keys ||= data.keys
             @keys.map { |key| data[key] }
           else
             data
           end

    @data.push list.map { |el| fmt(el) }.join(@delimiter)
  end

  def to_s
    if @keys
      @keys.map(&:to_s).join(@delimiter) + "\n" +
        @data.join($RS)
    else
      @data.join($RS)
    end
  end

  private

  def fmt(item)
    item = item.to_s.gsub($RS, '\\n').gsub('"', '""')

    item.include?(@delimiter) || item.include?('\\') ? "\"#{item}\"" : item
  end
end
