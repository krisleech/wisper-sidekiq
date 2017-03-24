# Wisper::Sidekiq

Provides [Wisper](https://github.com/krisleech/wisper) with asynchronous event
publishing using [Sidekiq](https://github.com/mperham/sidekiq).

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

The listener must be a class (or module), not an object. This is because Sidekiq
can not reconstruct the state of an object. However a class is easily reconstructed.

Additionally, you should also ensure that your methods used to handle events under `MyListener` are all declared as class methods:

```ruby
class MyListener
  def self.event_name
  end
end
```

When publshing events the arguments must be simple as they need to be
serialized. For example instead of sending an `ActiveRecord` model as an argument
use its id instead.

See the [Sidekiq best practices](https://github.com/mperham/sidekiq/wiki/Best-Practices)
for more information.

## Advanced options

You can also customize queue name, retry value and other sidekiq options when registering the listener like the following:

```ruby
publisher.subscribe(MyListener, async: { queue: 'custom', retry: false })
```

## Compatibility

The same Ruby versions as Sidekiq are offically supported, but it should work
with any 2.x syntax Ruby including JRuby and Rubinius.

See the [build status](https://travis-ci.org/krisleech/wisper-sidekiq) for details.


## Contributing

To run sidekiq use `scripts/sidekiq`. This wraps sidekiq in [rerun](https://github.com/alexch/rerun)
which will restart sidekiq when `specs/dummy_app` changes.
