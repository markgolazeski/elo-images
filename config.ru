require './app'
require 'envyable'

environment = ENV['ENVIRONMENT']

if not environment
  abort 'no ENVIRONMENT for config specified'
end

Envyable.load('./config/env.yml', environment)

run App.new
