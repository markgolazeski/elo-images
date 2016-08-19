class Photo

  attr_accessor :id, :src, :height, :width, :matches, :votes, :elo, :valid

  def initialize args
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    redis_connection = Redis.new
    redis_namespace = ENV['REDIS_NAMESPACE']

    if redis_namespace.nil?
      abort 'No REDIS_NAMESPACE environment variable'
    end

    $r = Redis::Namespace.new(redis_namespace, :redis => redis_connection)

    #if $r.nil?
    #  $r = Redis.new
    #end

    if $r.nil?
      abort("No redis in photo.rb?")
    end

    ['elo', 'matches', 'votes'].each do |k|
      key = "photo:#{self.id}:#{k}"
      stored = $r.get key

      unless stored.nil?
        instance_variable_set("@#{k}", stored)
      else
        $r.set(key, [0, instance_variable_get("@#{k}")].compact.max)

        if k == 'elo'
          $r.set(key, [1000, instance_variable_get("@#{k}")].compact.max)
        end
      end
    end

  end

  def id
    @id.to_i unless @id.nil?
  end

  def elo
    @elo.to_i unless @elo.nil?
  end

  def matches
    @matches.to_i unless @matches.nil?
  end

  def k_factor
    k_factor = 25
    if self.matches >= 30
      if self.elo < 2400
        k_factor = 15
      else
        k_factor = 10
      end
    end

    return k_factor
  end

  def valid?
    !!self.valid
  end

  def elo_key
    "photo:#{self.id}:elo"
  end

  def vote_key
    "photo:#{self.id}:votes"
  end

  def matches_key
    "photo:#{self.id}:matches"
  end

  def increment_votes
    $r.incr(vote_key)
  end

  def increment_matches
    $r.incr(self.matches_key)
  end

  def set_new_calculated_rating actual_win, other_rating
    my_rating = self.elo
    my_new_rating = my_rating + self.k_factor * (actual_win - (1.0 / (1 + 10 ** ((other_rating - my_rating) / 400.0))))
    my_new_rating = my_new_rating.ceil

    self.elo = my_new_rating
    $r.set(self.elo_key, self.elo)
    $r.zadd('top', self.elo, self.id)

    return my_new_rating
  end

end
