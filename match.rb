require 'redis'
require 'redis-namespace'
require 'securerandom'
require 'time'

require './photo'

class Match

  attr_accessor :id, :ip, :photo_1_id, :photo_2_id, :photo_1,
    :photo_2, :guid, :winning_photo_id, :created_at

  def initialize(args = nil)
    redis_connection = Redis.new
    redis_namespace = ENV['REDIS_NAMESPACE']

    if redis_namespace.nil?
      abort 'No REDIS_NAMESPACE environment variable'
    end

    if args.nil?
      $r = Redis::Namespace.new(redis_namespace, :redis => redis_connection)
      @id = $r.incr self.match_counter_key
      @guid = SecureRandom.uuid
      @created_at = Time.now.iso8601
    else
      $r = Redis::Namespace.new(redis_namespace, :redis => redis_connection)
      @id = args[:existing_id]

      existing_match = $r.hgetall(self.match_key)

      existing_match.each do |k, v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end
  end

  def match_counter_key
    self.class.match_counter_key
  end

  def self.match_counter_key
    'match_count'
  end

  def match_key
    "#{match_key_prefix}#{@id}"
  end

  def match_key_prefix
    self.class.match_key_prefix
  end

  def self.match_key_prefix
    "match:"
  end

  def winning_photo_id= winning_photo
    if winning_photo.nil?
      puts 'No winning photo passed in?'
      puts "winning_photo"
      puts winning_photo
      puts "_winning_photo"

      return self.winning_photo_id
    end

    @winning_photo_id = winning_photo.id

    $r.hset(self.match_key, 'winning_photo_id', @winning_photo_id)
    $r.sadd(self.match_finished_key, self.match_key)

    self.winning_photo_id
  end

  def winning_photo_id
    @winning_photo_id.to_i unless @winning_photo_id.nil?
  end

  # Doesn't include winning_photo_id
  def save
    unless @photo_1_id.nil? or @photo_2_id.nil?
      $r.hmset(self.match_key, 'photo_1_id', @photo_1_id, 'photo_2_id', @photo_2_id, 'ip', @ip, 'guid', @guid, 'created_at', @created_at)
      $r.expire(self.match_key, 86400)
    end
  end

  def photo_1_id
    @photo_1_id.to_i unless @photo_1_id.nil?
  end

  def photo_2_id
    @photo_2_id.to_i unless @photo_2_id.nil?
  end

  def match_finished_key
    self.class.match_finished_key
  end

  def self.match_finished_key
    'matches:finished'
  end

end
