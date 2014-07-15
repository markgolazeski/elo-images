require 'rubygems'
require 'json'
require 'sass/plugin/rack'
require 'sinatra'
require 'base64'
require 'haml'
require 'redis'
require 'rack-flash'

require './match'
require './photos'

set :static, true

use Sass::Plugin::Rack
Sass::Plugin.options.merge!(template_location: 'sass',
                            css_location: './public/css')


class App < Sinatra::Application
  # For Rack Flash, Only
  enable :sessions
  # TODO: Improve secret if sessions start really being used
  set :session_secret, 'seatec astronomy'
  use Rack::Flash, :sweep => true

  def initialize
    super
    @photos = (Photos.new).data
    @photos_lookup = {}
    @photos.each do |p|
      @photos_lookup[p.id] = p
    end

    $r = Redis.new
    if $r.nil?
      abort 'No redis?'
    end

    # Ensures current photos valid
    $r.del('top')

    if not $r.exists('top')
      @photos.each do |p|
        $r.zadd('top', p.elo, p.id)
      end
    end

    # Counters
    if not $r.exists('match_count')
      $r.set('match_count', 0)
    end

  end

  get '/' do
    haml :index
  end

  get %r{/images/([\d]+).png} do |id|
    "#{id} specified"
  end

  get '/debug' do
    haml :photos
  end

  get '/vote' do
    @notice = flash[:notice]

    photo_1 = nil
    photo_2 = nil

    # TODO: better way to do this?
    if @photos.size < 2
      abort('Not enough photos to vote?')
    end

    while photo_1 == photo_2
      photo_1 = @photos.sample
      photo_2 = @photos.sample
    end

    # Create match
    match = Match.new

    match.photo_1 = photo_1
    match.photo_2 = photo_2
    match.photo_1_id = photo_1.id
    match.photo_2_id = photo_2.id
    match.ip = request.ip

    match.save

    @match = match

    haml :vote
  end

  post '/vote' do
    match_id = params['match_id']
    guid = params['guid']
    winning_photo_id = params['photo_id_vote']
    winning_photo_id = winning_photo_id.to_i unless winning_photo_id.nil?

    match = Match.new(:existing_id => match_id)

    unless match.guid == guid
      puts "GUID From user does not match #{guid}: #{match.guid}"

      status 400
      body "Bad Match GUID"
      return
    end

    unless match.winning_photo_id.nil?
      puts "Already a winning photo id"
      status 400
      body "Vote already recorded"

      return
    end

    photo_1 = @photos_lookup[match.photo_1_id]
    photo_2 = @photos_lookup[match.photo_2_id]
    match.photo_1 = photo_1
    match.photo_2 = photo_2

    # Valid vote, update
    match.winning_photo_id = @photos_lookup[winning_photo_id]

    win_id = match.winning_photo_id

    photo_1.increment_matches
    photo_2.increment_matches

    if win_id.to_i == photo_1.id
      photo_1_elo, photo_2_elo = update_elos(photo_1, photo_2)
    elsif win_id.to_i == photo_2.id
      photo_2_elo, photo_1_elo = update_elos(photo_2, photo_1)
    else
      status 400
      puts "win_id, photo_1.id, photo_2.id"
      puts "#{win_id}, #{photo_1.id}, #{photo_2.id}"
      puts "_win_id, photo_1.id, photo_2.id"
      body "Bad Photo Vote id"
      return
    end

    $r.persist(match.match_key)
    $r.zadd('top', match.photo_1.elo, match.photo_1.id)
    $r.zadd('top', match.photo_2.elo, match.photo_2.id)

    flash[:notice] = "Successful Vote!"

    redirect '/vote'
  end

  get '/top' do
    top_ids = $r.zrevrange('top', 0, 5)
    @top_ids = top_ids

    @top_photos = top_ids.collect { |x| @photos_lookup[x.to_i] }

    # num votes == finished matches
    @num_votes = $r.scard(Match.match_finished_key)
    @num_photos = @photos_lookup.size

    haml :top
  end

  def update_elos winning_photo, losing_photo
    l_elo = losing_photo.elo
    w_elo = winning_photo.elo

    winning_photo.set_new_calculated_rating(1, l_elo)
    losing_photo.set_new_calculated_rating(0, w_elo)

    [winning_photo.elo, losing_photo.elo]
  end

end
