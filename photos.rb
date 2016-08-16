require 'json'
require 'redis'

require './photo'


class Photos


  attr_reader :data

  def initialize

    file_location = ENV['DATA_FILE_LOCATION']
    if file_location.nil?
      abort('No file_location from DATA_FILE_LOCATION specified')
    end
    file_path = File.join(File.dirname(__FILE__), file_location)

    unless File.exists? file_path
      abort "JSON #{file_path} not found!"
    end

    data = JSON.parse(IO.read(file_path))['data']
    photos =  data.collect { |x| Photo.new(x) }
    @data = photos.select{ |x| x.valid? }
  end


end
