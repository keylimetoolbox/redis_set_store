# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedisSetStore do
  it { expect(RedisSetStore.cache).to be_an ActiveSupport::Cache::Store }
  it { expect(RedisSetStore.cache).to be_an ActiveSupport::Cache::RedisStore }
end
