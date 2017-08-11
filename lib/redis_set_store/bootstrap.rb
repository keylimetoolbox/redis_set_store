# frozen_string_literal: true

module RedisSetStore
  # Bootstrap data into your cache to start using the RedisSetStore.
  #
  # RedisSetStore depends on looking up cache keys in redis sets to limit the
  # search scope when matching keys or deleting matched keys. If you have an
  # existing cache, then those set entries won't exist for the existing cache
  # entries and the RedisSetStore#matched and RedisSetStore#delete_matched
  # methods won't find any keys.
  #
  # To address that you can bootstrap your existing cache using this utility.
  #
  #   require "redis_set_store/bootstrap"
  #   bootstrap = RedisSetStore::Bootstrap.new
  #   bootstrap.bootstrap_set("user:1")
  #   bootstrap.bootstrap_set("user:2")
  #
  # Running this will use the redis KEYS method which is very slow (the reason
  # for this gem), so ideally set up a copy or slave of your cache redis
  # instance to use as a read source so you don't affect your running cache.
  # You can the configure the source for migration.
  #
  #   require "redis_set_store/bootstrap"
  #   slave     = Redis.new(host: "10.0.1.1")
  #   bootstrap = RedisSetStore::Bootstrap.new(source: slave)
  #   bootstrap.bootstrap_set("user:1")
  #   bootstrap.bootstrap_set("user:2")
  class Bootstrap
    # Creates a new Bootstrap utility.
    #
    # source:      The source Redis instance. If not provided uses
    #              the destination redis or RedisSetStore.cache.redis, which
    #              under Rails is the configure Rails.cache store.
    #
    # destination: The destination Redis instance. If not provided uses
    #              RedisSetStore.cache.redis as a default, which under Rails
    #              is the configure Rails.cache store.
    def initialize(source: nil, destination: nil)
      @source      = source || destination || RedisSetStore.cache.redis
      @destination = destination || RedisSetStore.cache.redis
    end

    # Bootstrap a redis set for the matching keys in the cache.
    #
    # prefix: The prefix to match for keys and to use as the set key.
    #
    # Reads all keys from the `source` redis instance that match the prefix
    # (followed by ":") and records them in the set used by RedisSetStore.
    # The prefix is expected to the be the same as the `set_owner_regexp`
    # parameters for ActiveSupport::Cache::RedisSetStore.
    #
    # Note that because this uses the KEYS method in Redis it scans _every key_
    # in the database each time it is called which can be slow and will lock
    # your database. You should configure a separate redis instance to read
    # from as described in RedisSetStore::Bootstrap or run this with the
    # cache offline.
    def bootstrap_set(prefix)
      keys = @source.keys "#{prefix}:*"
      return if keys.empty?
      set_manager.sadd(prefix, keys)
    end

    private

    def set_manager
      return @set_manager if @set_manager

      if defined?(ActiveSupport::Cache::RedisSetStore::SetOwner::STORE)
        return @set_manager = ActiveSupport::Cache::RedisSetStore::SetOwner::STORE
      end

      @set_manager = @destination
    end
  end
end
