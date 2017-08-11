# RedisSetStore

A Rails cache implementation that is backed by redis and uses sets to track
keys for rapid expiration of large numbers of keys.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_set_store'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_set_store

## Usage

You can use the `RedisSetStore` as you would any other Rails cache store by
configuring it in your environment files:

```ruby
# config/application.rb
config.cache_store = :redis_set_store
```

`RedisSetStore` allows you to regularly remove large numbers of keys with
wildcard patterns, using `#delete_matched`.

```ruby
def cache_key_prefix
  "#{self.class.to_s.tableize.singularize}:#{id}:"
end

def expire_cache
  Rails.cache.delete_matched("#{cache_key_prefix}*")
end
```

### How it works

Under the original [`RedisStore`](https://github.com/redis-store/redis-store)
`#delete_matched` calls the Redis `KEYS` method which scans _every_ key in your
database. If you have millions of cache keys this can take a long time and make
your server unresponsive.

`RedisSetStore` resolves this by maintaining a `set` of keys and checking the
members of that set when matching. Additionally, it partitions sets based on
a pattern. The default pattern is `\A[^:]\d+`, so if you have keys named as
follows, there would be a set for each object (e.g. `user:1`, `user:2`,
`report:1`, etc.):

```
user:1:profile
user:1:reports
user:2:profile
user:2:reports
report:1:metadata
report:2:metadata
```

Partitioning the sets allows for much faster look up of matched keys because
the cache doesn't have to retrieve all the keys in your database and try to
match every one.

Depending on your cache names, you may want to use a different pattern. You
can configure this with the first parameter to the `cache_store` configuration
value as shown above (e.g. `/\Auser:\d+/`). Note that the pattern does not have
to be a prefix. It could match any part of the key.

### Configuration

In your `config/application.rb`, (or files in `config/environments`), you can
pass a regular expression to partition your keys for sets and parameters for
the redis instance to connect to. If you don't want to change the default
partitioning pattern, the redis options can be the first parameter:

```ruby
config.cache_store = :redis_set_store
# or
config.cache_store = :redis_set_store, "redis://localhost:6379/0"
# or
config.cache_store = :redis_set_store, {
                                         host: "localhost",
                                         port: 6379,
                                         db: 0,
                                         password: "mysecret",
                                         namespace: "cache"
                                       }
```

If you are setting the regular expression for partitioning, then you must pass
that as the first parameter, and redis configuration follows.

```ruby
config.cache_store = :redis_set_store, /\Auser:\d+/
# or
config.cache_store = :redis_set_store, /\Auser:\d+/, "redis://localhost:6379/0"
# or
config.cache_store = :redis_set_store, /\Auser:\d+/, {
                                                       host: "localhost",
                                                       port: 6379,
                                                       db: 0,
                                                       password: "mysecret",
                                                       namespace: "cache"
                                                     }
```

See the [`redis-rails`](https://github.com/redis-store/redis-rails) gem for
more details on how to configure the redis connection.

### Migrating an Existing Cache

As `RedisSetStore` looks up cache keys in redis sets, if you have an existing
cache, then those set entries won't exist for the existing cache entries and
the `RedisSetStore#matched` and `RedisSetStore#delete_matched` methods won't
find any keys.

To address this we provide the `RedisSetStore::Bootstrap` utility. See the
documentation for that class for details.

## Contributing

1. Fork it ( https://github.com/keylimetoolbox/redis_set_store/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


### Redis Installation

#### Option 1: Homebrew

MacOS X users should use [Homebrew](https://github.com/mxcl/homebrew) to
install Redis:

```shell
brew install redis
```

#### Option 2: From Source

Download and install Redis from [the download page](http://redis.io//download)
and follow the instructions.

### Running tests

```ruby
bin/setup
bundle exec rake
```
