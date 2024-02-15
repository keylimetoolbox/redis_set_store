# frozen_string_literal: true

module RedisSetStore
  class Railtie < Rails::Railtie
    initializer 'Blueprint::Cache logger' do
      RedisSetStore.logger = Rails.logger
    end

    initializer 'Blueprint::Cache cache' do
      RedisSetStore.cache = Rails.cache
    end
  end
end
