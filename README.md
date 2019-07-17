# Wisper::Sidekiq

Provides [Wisper](https://github.com/krisleech/wisper) with asynchronous event
publishing using [Sidekiq](https://github.com/mperham/sidekiq).

[![Gem Version](https://badge.fury.io/rb/wisper-sidekiq.png)](http://badge.fury.io/rb/wisper-sidekiq)
[![Code Climate](https://codeclimate.com/github/krisleech/wisper-sidekiq.png)](https://codeclimate.com/github/krisleech/wisper-sidekiq)
[![Build Status](https://travis-ci.org/krisleech/wisper-sidekiq.png?branch=master)](https://travis-ci.org/krisleech/wisper-sidekiq)
[![Coverage Status](https://coveralls.io/repos/krisleech/wisper-sidekiq/badge.png?branch=master)](https://coveralls.io/r/krisleech/wisper-sidekiq?branch=master)

## Installation

### Sidekiq 5+

```ruby
gem 'wisper-sidekiq', '~> 1.0'
```

### Sidekiq 4-

```ruby
gem 'wisper-sidekiq', '~> 0.0'
```

## Usage

```ruby
publisher.subscribe(MyListener, async: true)
```

The listener must be a class (or module), not an object. This is because Sidekiq
can not reconstruct the state of an object. However a class is easily reconstructed.

Additionally, you should also ensure that your methods used to handle events under `MyListener` are all declared as class methods:

```ruby
class MyListener
  def self.event_name
  end
end
```

When publishing events the arguments must be simple as they need to be
serialized. For example instead of sending an `ActiveRecord` model as an argument
use its id instead.

See the [Sidekiq best practices](https://github.com/mperham/sidekiq/wiki/Best-Practices)
for more information.

### Passing down sidekiq options

In order to define custom [sidekiq_options](https://github.com/mperham/sidekiq/wiki/Advanced-Options#workers) you can add `sidekiq_options` class method in your subscriber definition - those options will be passed to Sidekiq's `set` method just before scheduling the asynchronous worker.

## Compatibility

The same Ruby versions as Sidekiq are offically supported, but it should work
with any 2.x syntax Ruby including JRuby and Rubinius.

See the [build status](https://travis-ci.org/krisleech/wisper-sidekiq) for details.

## Running Specs

```
scripts/sidekiq
bundle exec rspec
```

## Contributing

To run sidekiq use `scripts/sidekiq`. This wraps sidekiq in [rerun](https://github.com/alexch/rerun)
which will restart sidekiq when `specs/dummy_app` changes.
