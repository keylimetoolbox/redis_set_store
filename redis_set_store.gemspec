# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_set_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis_set_store'
  spec.version       = RedisSetStore::VERSION
  spec.authors       = ['Jeremy Wadsack']
  spec.email         = ['jeremy.wadsack@gmail.com']
  spec.summary       = 'A Rails cache implementation, backed by redis, for rapid expiration of lots of keys'
  spec.description   = 'A Rails cache implementation that is backed by redis and uses sets to track keys for rapid ' \
                       'expiration of large numbers of keys'
  spec.homepage      = 'https://github.com/keylimetoolbox/redis_set_store'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'railties', '>= 4.2'
  spec.add_dependency 'redis', '~> 5.1'
  spec.add_dependency 'redis-rails', '~> 5.0.2'
  spec.add_dependency 'redis-store', '~> 1.10'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
