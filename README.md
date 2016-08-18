Metadata about pictures stored in JSON.

Loaded every time, but then values overwritted if they are contained in redis.

Redis store holds info on matches/votes/elos, and maintains sorted set of photos scored by elo.

To run locally with sample example environment data (no photos):
```
cp ./config/example.yml ./config/env.yml```
ENVIRONMENT=example unicorn
```


Simple redis maintenance:
```
redis-cli
```

To see keys created within example namespace:
```
keys example:*
```

To remove all keys with example prefix
```
EVAL "return redis.call('del', unpack(redis.call('keys', ARGV[1])))" 0 example:*
```
