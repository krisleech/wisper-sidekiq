# Wisper::Sidekiq

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
publisher.subscribe(MyListener, broadcaster: Wisper::Sidekiq.new)

publisher.run
```

Note that the listener must be a class (or module), not an object.

## Contributing

To run sidekiq `scripts/sidekiq`. This wraps sidekiq in rerun which will watch
`specs/dummy_app` for changes.
