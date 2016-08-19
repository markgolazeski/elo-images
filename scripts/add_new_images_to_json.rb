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

data_file_location = ENV['DATA_FILE_LOCATION']
if data_file_location.nil?
  abort 'No Data File Location'
end

data = File.read(data_file_location)

json_data = JSON.parse(data)

ids = []
srcs = []
json_data["data"].each do |k|
  ids.push(k["id"].to_i)
  srcs.push(k["src"])
end

# Get max id
max_id = ids.max()

# remove trailing slash
folder = "public/images#{images_subdirectory}"[0..-2]
files = `find #{folder} -depth 1 -iname "\*.q.png"`
files =  files.split("\n").compact
old_files = files.map do |x|
  x.sub(/public\//, '')
end

new_files = old_files - srcs
new_files.each do |new_file|
  photo_id = new_file.split('/')[2].split('.')[0].to_i
  new_data = {}
  new_data['id'] = photo_id
  new_data['src'] = new_file
  width, height = FastImage.size("./public/#{new_data['src']}")
  new_data['width'] = width
  new_data['height'] = height
  new_data['valid'] = true
  json_data["data"].push(new_data)
end

puts JSON.pretty_generate(json_data)
