# frozen_string_literal: true

require 'spec_helper'
require 'redis_set_store/bootstrap'

RSpec.describe RedisSetStore::Bootstrap do
  subject { RedisSetStore::Bootstrap.new }

  let(:primary_cache) { RedisSetStore.cache.instance_variable_get(:@data) }

  shared_examples_for 'bootstrap_set' do
    context 'with no matching keys in the source cache' do
      before do
        expect(source_redis.keys('cacheable_object:27:*')).to be_empty
        expect(redis_set_store.smembers('cacheable_object:27').count).to eq 0
      end

      it 'does nothing' do
        subject.bootstrap_set('cacheable_object:27')
        expect(redis_set_store.smembers('cacheable_object:27').count).to eq 0
      end
    end

    context 'with matching keys in the source cache' do
      before do
        source_redis.set('cacheable_object:27:key1', 7)
        source_redis.set('cacheable_object:27:key2', 8)
        expect(redis_set_store.smembers('cacheable_object:27').count).to eq 0
      end

      it 'copies existing keys to the redis set' do
        subject.bootstrap_set('cacheable_object:27')
        expected = ['cacheable_object:27:key1', 'cacheable_object:27:key2']
        expect(redis_set_store.smembers('cacheable_object:27').count).to eq 2
        expect(redis_set_store.smembers('cacheable_object:27')).to match_array expected
      end
    end
  end

  shared_examples_for 'bootstrap_set for dependent, independent set management' do
    context 'when the Redis sets are managed in the same store as the rest of the cache' do
      let(:redis_set_store) { primary_cache }

      include_examples 'bootstrap_set'
    end

    context 'when the Redis sets are managed in a separate store' do
      let(:redis_set_store) { Redis.new(db: 14) }

      before do
        ActiveSupport::Cache::RedisSetStore::SetOwner::STORE = redis_set_store
      end

      after do
        redis_set_store.flushdb
        ActiveSupport::Cache::RedisSetStore::SetOwner.send(:remove_const, :STORE)
      end

      include_examples 'bootstrap_set'
    end
  end

  context 'when the copy source is the primary cache' do
    let(:source_redis) { primary_cache }

    include_examples 'bootstrap_set for dependent, independent set management'
  end

  context 'when the copy source is defined to be other than the primary cache' do
    let(:source_redis) { Redis.new(db: 13) }

    subject { RedisSetStore::Bootstrap.new(source: source_redis) }

    after do
      source_redis.flushdb
    end

    include_examples 'bootstrap_set for dependent, independent set management'
  end
end
