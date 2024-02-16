# frozen_string_literal: true

require 'bundler/setup'
require 'redis_set_store'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :mocha
  config.order = 'random'

  config.after do
    RedisSetStore.cache.clear
  end
end

RedisSetStore.logger = ActiveSupport::TaggedLogging.new(Logger.new('/dev/null'))

# NOTE: the string 'cacheable_object' is used in the specs of this gem
set_regexp = /cacheable_object:\d+/
redis_options = { host: '127.0.0.1', port: '6379', db: 15 }
RedisSetStore.cache = ActiveSupport::Cache::RedisSetStore.new(set_regexp, redis_options)
