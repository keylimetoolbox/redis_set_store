# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "redis_set_store/version"

Gem::Specification.new do |spec|
  spec.name          = "redis_set_store"
  spec.version       = RedisSetStore::VERSION
  spec.authors       = ["Jeremy Wadsack"]
  spec.email         = ["jeremy.wadsack@gmail.com"]
  spec.summary       = "A Rails cache implementation, backed by redis, for rapid expiration of lots of keys"
  spec.description   = "A Rails cache implementation that is backed by redis and uses sets to track keys for rapid "\
                        "expiration of large numbers of keys"
  spec.homepage      = "https://github.com/keylimetoolbox/redis_set_store"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "mocha", "~> 1"
  spec.add_development_dependency "appraisal", "~> 2.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "bundler-audit"

  spec.add_dependency "activesupport", ">= 4.2"
  spec.add_dependency "railties", ">= 4.2"
  spec.add_dependency "redis-rails", ">= 3.0"
  spec.add_dependency "redis", "~> 3.0"
  spec.add_dependency "redis-store", "~> 1.1"
end
