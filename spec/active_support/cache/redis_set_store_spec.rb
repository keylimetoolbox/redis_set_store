# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveSupport::Cache::RedisSetStore do

  class SetOwner
    def initialize(id)
      @id = id
    end

    def set_identifier
      # See spec_helper where the Regexp for RedisSetStore contains "cacheable_object"
      "cacheable_object:#{@id}"
    end
  end

  let(:owner) { SetOwner.new(1234) }
  let(:other_owner) { SetOwner.new(5678) }

  let(:key) { "#{owner.set_identifier}:some:key" }
  let(:owner_key1) { "#{owner.set_identifier}:key:1" }
  let(:owner_key2) { "#{owner.set_identifier}:key:2" }
  let(:owner_key_with_special_meaning_chars) { "#{owner.set_identifier}:key:L#{special_meaning_character} Breakfast" }
  let(:other_owner_key1) { "#{other_owner.set_identifier}:key:1" }

  shared_examples_for "matched" do

    context "matcher converts wildcards to regexp" do

      before do
        RedisSetStore.cache.write(owner_key1, 1)
        RedisSetStore.cache.write(owner_key2, 2)
        RedisSetStore.cache.write(owner_key_with_special_meaning_chars, 3)
        RedisSetStore.cache.write(other_owner_key1, 1)
      end

      it "returns all the keys of the set owner with owner's set_identifier suffixed with a wildcard" do
        result = RedisSetStore.cache.matched("#{owner.set_identifier}*")
        expect(result).to match_array [owner_key1, owner_key2, owner_key_with_special_meaning_chars]
      end

      it "returns only matching keys of the set owner when additionally filtered" do
        result = RedisSetStore.cache.matched("#{owner.set_identifier}*:2")
        expect(result).to match_array [owner_key2]
      end

      it "returns only matching keys of the set owner when additionally filtered with special meaning chars" do
        result = RedisSetStore.cache.matched("#{owner.set_identifier}*:L#{special_meaning_character} Breakfast")
        expect(result).to match_array [owner_key_with_special_meaning_chars]
      end
    end
  end

  shared_examples_for "delete_matched" do

    context "convert wildcards to regexp" do

      before do
        RedisSetStore.cache.write(owner_key1, 1)
        RedisSetStore.cache.write(owner_key2, 2)
        RedisSetStore.cache.write(owner_key_with_special_meaning_chars, 3)
        RedisSetStore.cache.write(other_owner_key1, 1)
      end

      context "when owner's set identifier is suffixed with a wildcard" do

        before do
          RedisSetStore.cache.delete_matched("#{owner.set_identifier}*")
        end

        it "removes all the keys from the owner set" do
          expect(redis_set_store.smembers(owner.set_identifier).count).to eq 0
        end

        it "removes all the owner's keys from the cache" do
          expect(RedisSetStore.cache.read(owner_key1)).to be_nil
          expect(RedisSetStore.cache.read(owner_key2)).to be_nil
          expect(RedisSetStore.cache.read(owner_key_with_special_meaning_chars)).to be_nil
        end

        it "does NOT remove any keys from the other owner's set" do
          expect(redis_set_store.smembers(other_owner.set_identifier).count).to eq 1
        end

        it "does NOT remove the other owner's keys from the cache" do
          expect(RedisSetStore.cache.read(other_owner_key1)).to eq 1
        end
      end

      context "when owner's set identifier is further filtered with a special meaning character" do

        before do
          RedisSetStore.cache.delete_matched("#{owner.set_identifier}*:L#{special_meaning_character} Breakfast")
        end

        it "removes matching keys from the owner set" do
          expect(redis_set_store.smembers(owner.set_identifier).count).to eq 2
          expect(redis_set_store.smembers(owner.set_identifier)).to match_array [owner_key1, owner_key2]
        end

        it "removes matching owner's keys from the cache" do
          expect(RedisSetStore.cache.read(owner_key1)).to eq 1
          expect(RedisSetStore.cache.read(owner_key2)).to eq 2
          expect(RedisSetStore.cache.read(owner_key_with_special_meaning_chars)).to be_nil
        end

        it "does NOT remove any keys from the other owner's set" do
          expect(redis_set_store.smembers(other_owner.set_identifier).count).to eq 1
        end

        it "does NOT remove the other owner's keys from the cache" do
          expect(RedisSetStore.cache.read(other_owner_key1)).to eq 1
        end
      end

      context "when owner's set identifier is further filtered" do

        before do
          RedisSetStore.cache.delete_matched("#{owner.set_identifier}*:2")
        end

        it "removes matching keys from the owner set" do
          expected = [owner_key1, owner_key_with_special_meaning_chars]
          expect(redis_set_store.smembers(owner.set_identifier).count).to eq 2
          expect(redis_set_store.smembers(owner.set_identifier)).to match_array expected
        end

        it "removes matching owner's keys from the cache" do
          expect(RedisSetStore.cache.read(owner_key1)).to eq 1
          expect(RedisSetStore.cache.read(owner_key2)).to be_nil
          expect(RedisSetStore.cache.read(owner_key_with_special_meaning_chars)).to eq 3
        end

        it "does NOT remove any keys from the other owner's set" do
          expect(redis_set_store.smembers(other_owner.set_identifier).count).to eq 1
        end

        it "does NOT remove the other owner's keys from the cache" do
          expect(RedisSetStore.cache.read(other_owner_key1)).to eq 1
        end
      end
    end
  end

  shared_examples_for "cache owner store" do

    after do
      redis_set_store.flushdb
    end

    context "write_entry" do

      before do
        RedisSetStore.cache.write(key, 7)
      end

      it "adds the key to a set for the owner" do
        expect(redis_set_store.smembers(owner.set_identifier)).to include key
      end

      it "writes the key and value to the cache" do
        expect(RedisSetStore.cache.read(key)).to eq 7
      end

      # Not sure this is needed, as it's testing Redis set behavior
      it "behaves as a Redis set.  Duplicate keys are NOT created" do
        RedisSetStore.cache.write(key, 5)
        expect(redis_set_store.smembers(owner.set_identifier).count).to eq 1
        expect(redis_set_store.smembers(owner.set_identifier)).to match_array [key]
      end

      it "prevents writing a key with the character '*' (not-supported by the matching algorithm)" do
        expect { RedisSetStore.cache.write("some * key", 5) }.to raise_error ArgumentError
      end
    end

    context "delete_entry" do

      before do
        RedisSetStore.cache.write(key, 7)
        RedisSetStore.cache.delete(key)
      end

      it "removes the key from the set for the owner" do
        expect(redis_set_store.smembers(owner.set_identifier).count).to eq 0
      end

      it "removes the key from the cache" do
        expect(RedisSetStore.cache.read(key)).to be_nil
      end

      # Not sure this is needed, as it's testing Redis set and cache behavior
      it "does NOT fail if the key doesn't already exist in the cache or set" do
        expect { RedisSetStore.cache.delete("test:cache:#{owner.set_identifier}:other:key") }.to_not raise_error
      end
    end

    [".", ")", "(", "/", "^", "$", "|", "?", "{", "}", "[", "]", " +"].each do |char|
      context "matching special meaning character #{char}" do
        let(:special_meaning_character) { char }
        include_examples "matched"
        include_examples "delete_matched"
      end
    end

  end

  context "when the Redis sets are managed in the same store as the rest of the cache" do
    let(:redis_set_store) { RedisSetStore.cache.redis }

    include_examples "cache owner store"
  end

  context "when the Redis sets are managed in a separate store" do
    let(:redis_set_store) { Redis.new(db: 14) }

    before do
      ActiveSupport::Cache::RedisSetStore::SetOwner::STORE = redis_set_store
    end

    after do
      ActiveSupport::Cache::RedisSetStore::SetOwner.send(:remove_const, :STORE)
    end

    include_examples "cache owner store"

    context "ping" do

      it "calls ping on the RedisSetStore cache Redis instance and the Redis Set Store instance" do
        redis_set_store.expects(:ping)
        RedisSetStore.cache.redis.expects(:ping)
        RedisSetStore.cache.ping
      end
    end
  end
end
