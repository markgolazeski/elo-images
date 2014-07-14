require 'json'
require 'redis'

require './photo'


class Photos


  FILE_LOCATION = "data/photos.json"

  attr_reader :data

  def initialize

    file_path = File.join(File.dirname(__FILE__), FILE_LOCATION)

    unless File.exists? file_path
      abort "JSON #{file_path} not found!"
    end

    data = JSON.parse(IO.read(file_path))['data']
    photos =  data.collect { |x| Photo.new(x) }
    @data = photos.select{ |x| x.valid? }
  end


end
