#!/usr/bin/env ruby

require 'envyable'
require 'redis'
require 'redis-namespace'
require 'json'
require 'fastimage'

environment = ENV['ENVIRONMENT']

if not environment
  abort 'no ENVIRONMENT for config specified'
end

Envyable.load('./config/env.yml', environment)

images_subdirectory = ENV['IMAGES_SUBDIRECTORY']
if images_subdirectory.nil?
  abort 'No Images Subdirectory'
end
src_dir = "images#{images_subdirectory}"

redis_connection = Redis.new
redis_namespace = ENV['REDIS_NAMESPACE']

if redis_namespace.nil?
  abort 'No REDIS_NAMESPACE environment variable'
end

r = Redis::Namespace.new(redis_namespace, :redis => redis_connection)

photo_data = {}

r.keys('photo:*:*').each do |k|
  photo_id = k.split(":")[1].to_i
  unless photo_data.has_key?(photo_id)
    photo_data[photo_id] = {}
    photo_data[photo_id]['id'] = photo_id
    photo_data[photo_id]['src'] = "#{src_dir}#{photo_id}.q.png"
    width, height = FastImage.size("./public/#{photo_data[photo_id]['src']}")
    photo_data[photo_id]['width'] = width
    photo_data[photo_id]['height'] = height
    photo_data[photo_id]['valid'] = true
  end

  data_key = k.split(":")[2]
  data_value = r.get(k)

  photo_data[photo_id][data_key] = data_value
end

photos = []

photo_data_keys = photo_data.keys.sort

sorted_photo_data = photo_data_keys.map do |x|
  photo_data[x]
end

puts JSON.pretty_generate({:data => sorted_photo_data})
