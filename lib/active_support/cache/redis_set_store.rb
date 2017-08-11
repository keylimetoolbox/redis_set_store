# frozen_string_literal: true

module ActiveSupport
  module Cache
    # A Rails cache implementation that is backed by redis and uses sets to
    # track keys for rapid expiration of large numbers of keys.
    #
    # Generally you would set this up in your Rails environment files:
    #
    #   # production.rb
    #   Rails.application.configure do
    #     config.cache_store = :redis_set_store, /\Auser:\d+/
    #   end
    class RedisSetStore < RedisStore
      # Instantiate the store.
      #
      # set_owner_regexp: A regular expression that identifies keys within a given
      #                   Set Owner's Redis set.
      #
      #                   For example, assume a Site model owns cache sets.
      #                   These are defined with the cache key prefix
      #                   "site:#{site.id}". So the appropriate argument would
      #                   be: `/\Asite:\d+/`
      #
      #                   If not provided (or `nil` is provided), the default
      #                   pattern is `/\A[^:]+:\d+/`. That is, it matches
      #                   any pattern like "type:1", assuming
      #
      # redis_options: Standard redis_options for a ActiveSupport::Cache::RedisStore
      #
      # Example:
      #   RedisSetStore.new
      #     # => pattern: /\A[^:]+:\d+/, host: localhost,   port: 6379,  db: 0
      #
      #   RedisSetStore.new(/\Asite:\d+/)
      #     # => pattern: /\Asite:\d+/,  host: localhost,   port: 6379,  db: 0
      #
      #   RedisSetStore.new(/\Asite:\d+/, "example.com")
      #     # => pattern: /\Asite:\d+/,  host: example.com, port: 6379,  db: 0
      #
      #   RedisSetStore.new(/\Asite:\d+/, "example.com:23682")
      #     # => pattern: /\Asite:\d+/,  host: example.com, port: 23682, db: 0
      #
      #   RedisSetStore.new(/\Asite:\d+/, "example.com:23682/1")
      #     # => pattern: /\Asite:\d+/,  host: example.com, port: 23682, db: 1
      #
      # See more examples at ActiveSupport::Cache::RedisStore
      def initialize(set_owner_regexp = nil, redis_options = {})
        if set_owner_regexp.is_a?(Regexp)
          @set_owner_regexp = set_owner_regexp
        else
          redis_options    = set_owner_regexp
          set_owner_regexp = nil
        end
        @set_owner_regexp = set_owner_regexp || /\A[^:]+:\d+/

        super(redis_options)
      end

      # Delete objects for matched keys.
      #
      # Example:
      #   cache.delete_matched("user:1:rab*")
      #
      # Returns number of keys that were deleted or `nil` if a connection error occurs.
      def delete_matched(matcher, _options = nil)
        SetOwner.new(@set_owner_regexp, matcher, @data).delete_matched
      rescue Errno::ECONNREFUSED
        nil
      end

      # Find matched keys.
      #
      # Example:
      #   cache.matched("user:1:rab*")
      #
      # Returns an array of matching keys or `nil` if a connection error occurs.
      def matched(key)
        SetOwner.new(@set_owner_regexp, key, @data).matched
      rescue Errno::ECONNREFUSED
        []
      end

      # Ping the server.
      #
      # Returns "PONG" on success.
      def ping
        SetOwner::STORE&.ping if defined?(SetOwner::STORE)
        redis.ping
      end

      # Instance of redis where the cache data is stored.
      #
      # Returns a Redis instance.
      def redis
        @data
      end

      protected

      def write_entry(key, entry, options)
        if key.include?("*")
          raise ArgumentError.new("Unsupported Redis key character for ActiveSupport::Cache::RedisSetStore: *")
        end

        SetOwner.new(@set_owner_regexp, key, @data).sadd

        super
      rescue Errno::ECONNREFUSED
        false
      end

      def delete_entry(key, options)
        SetOwner.new(@set_owner_regexp, key, @data).srem

        super
      rescue Errno::ECONNREFUSED
        false
      end

      # Redis set wrapper for a given partition.
      class SetOwner
        def initialize(set_owner_regexp, key, redis)
          @key = key
          @set = nil
          match = set_owner_regexp.match(key)
          @set = match[0] if match
          @redis = redis
          @redis_set_store = STORE if defined?(STORE)
          @redis_set_store ||= @redis
        end

        def sadd
          return unless @set && @key
          @redis_set_store.sadd(@set, @key)
        end

        def srem
          return unless @set && @key
          @redis_set_store.srem(@set, @key)
        end

        def delete_matched
          return unless @set && @key

          srem_list = matched
          return if srem_list.blank?

          @redis_set_store.srem(@set, srem_list)
          @redis.del(srem_list)
        end

        def matched
          return unless @set && @key
          matcher_regexp = Regexp.compile(convert_wildcards_to_regex)
          @redis_set_store.smembers(@set).select { |smember| matcher_regexp.match(smember) }
        end

        # Redis wildcard character "*" is converted to the Regexp ".*".
        # All other special characters are normally-escaped.
        def convert_wildcards_to_regex
          key = Regexp.escape(@key.to_s)
          key = key.to_s.gsub("\\*", ".*")
          key << "$"
        end
      end
    end
  end
end
