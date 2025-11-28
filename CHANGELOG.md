# v2.0.0 (2025-11-26)
**Breaking Changes**
- Replace deprecated `redis-rails` with `redis-activesupport` for Rails 7.1 compatibility
- Remove explicit `redis-store` dependency (now transitive via `redis-activesupport`)

**Improvements**
- Add support for Rails 7.1
- Add `require 'active_support/core_ext/hash'` for Rails 7.1 compatibility

# v1.0.0
- Initial stable release
- Redis-backed cache store for Rails
- Set-based key tracking for rapid expiration of large numbers of keys
