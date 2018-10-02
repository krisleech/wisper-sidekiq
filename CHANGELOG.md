## [Unreleased]

- fixes: allow for Sidekiq 5

## [1.1.0] - 28/Sept/2018

- fixes: `NoMethodError: undefined method `set' for
  Wisper::SidekiqBroadcaster::Worker:Class` when using Sidekiq 2.x and 3.x.

## [1.0.0] - 28/Sept/2018

### Added
- sidekiq 5 compatibility (closes [#11](https://github.com/krisleech/wisper-sidekiq/issues/11))
- support for optional `sidekiq_options` per subscriber class (closes [#15](https://github.com/krisleech/wisper-sidekiq/issues/15))

## [0.0.1] - 06-10-2014

### Added
- Initial release
