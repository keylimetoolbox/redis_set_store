# frozen_string_literal: true

require "active_support"
require "redis"
require "redis-activesupport"

require "redis_set_store/version"
require "active_support/cache/redis_set_store"
require "redis_set_store/railtie" if defined? Rails

# A Rails cache implementation that is backed by redis and uses sets to track
# keys for rapid expiration of large numbers of keys.
module RedisSetStore
  mattr_accessor :logger, :cache
end

unless defined? Rails
  RedisSetStore.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  RedisSetStore.cache  = ActiveSupport::Cache::RedisSetStore.new(/\A[^:]+:\d+/)
end
