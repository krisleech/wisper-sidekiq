# Wisper::Sidekiq

NOTE: This gem will not work until Wisper > 1.4.0 is released.

Provides Wisper with async event publishing using Sidekiq.

[![Gem Version](https://badge.fury.io/rb/wisper-sidekiq.png)](http://badge.fury.io/rb/wisper-sidekiq)
[![Code Climate](https://codeclimate.com/github/krisleech/wisper-sidekiq.png)](https://codeclimate.com/github/krisleech/wisper-sidekiq)
[![Build Status](https://travis-ci.org/krisleech/wisper-sidekiq.png?branch=master)](https://travis-ci.org/krisleech/wisper-sidekiq)
[![Coverage Status](https://coveralls.io/repos/krisleech/wisper-sidekiq/badge.png?branch=master)](https://coveralls.io/r/krisleech/wisper-sidekiq?branch=master)

## Installation

```ruby
gem 'wisper-sidekiq'
```

## Usage

```ruby
publisher.subscribe(MyListener, async: true)
```

Note that the listener must be a class (or module), not an object. This is
because Sidekiq can not reconstruct the state of an object. However a class is
easily reconstructed.

When publshing events the arguments must be simple as they need to be
serialized. For example instead of sending an ActiveRecord model as an argument
use its id instead.

See the [Sidekiq best practices](https://github.com/mperham/sidekiq/wiki/Best-Practices)
for more information.

## Contributing

To run sidekiq `scripts/sidekiq`. This wraps sidekiq in rerun which will watch
`specs/dummy_app` for changes.
