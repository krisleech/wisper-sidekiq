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

In order be able to schedule jobs to be run in the future following [Scheduled Jobs](https://github.com/mperham/sidekiq/wiki/Scheduled-Jobs) you can add `sidekiq_options` class method in your subscriber definition - those options will be passed to Sidekiq's `perform_in` method when the worker is called.

This feature is not as powerfull as Sidekiq's API that allows you to set this on every job enqueue, in this case you're able to set this for the hole listener class like:
```ruby
class MyListener
  def self.sidekiq_options
    # If you don't wanna debounce, but instead, just schedule to run in the future, use `perform_in` option
    { queue: 'my_custom_queue', retry: false, perform_in: 15 }

    # in_seconds: the amount of time to debounce the events
    # expire_in_seconds: the amount of time for the key to stay present on redis cache
    # keys: you can define an array of attributes which debounce will look for on arguments to create an unique key to identify the debouncing jobs
    # NOTICE: If you pass a KEY that is not part of your arguments, you may cause inconsistent debouncing
    { debounce: { in_seconds: 15, expire_in_seconds: 60*60, keys: [:user_id, :email] } }
  end
end
```

### Using the debounce feature

This is a new feature that was implemented in order to prevent broadcasting messages to be processed multiple times
for the same event. This is useful if, for some instance, your class is subscribed to many channels/events, and you don't
want the job to process one time for each of the events.

Under the hood Redis is used to store an unique key created based on the

```ruby
class MyListener
  def self.sidekiq_options
    # in_seconds: the amount of time to debounce the events. Could be a Proc (resulting in a String or Integer) or directly an integer/string.
    # expire_in_seconds: the amount of time for the key to stay present on redis cache
    # keys: you can define an array of attributes which debounce will look for on arguments to create an unique key to identify the debouncing jobs
    # NOTICE 1: If you pass a KEY that is not part of your arguments, you may cause inconsistent debouncing
    # NOTICE 2: `debounce: { in_seconds: 15 }` will IGNORE the `perform_in` argument
    { debounce: { in_seconds: 15, expire_in_seconds: 60*60, keys: [:user_id, :email] } }
  end
end
```

The `keys` option allow you to use both named arguments or methods without named arguments.
All you have to do is specify the number/position of the arguments.
Let's say you have a method that receives `my_method(value1, value2)`.
If you want to use `value2` as the debounce key, all you have to do is this:

```ruby
class MyListener
  def self.sidekiq_options
    # KEYS: can receive the name of the argument, or the position
    # 1 here represents `value2`, since because arguments start with position 0
    { debounce: { in_seconds: 15, keys: [1] } }
  end

  def perform(value1, value2)
    # do something...
  end
end
```

The `overwrite_event_name` can be used to uniquely identify the whole class and it's events, no matter how many of
them you have this class subscribed to, all of the events are gonna to have the same event name, which is used to
compound the `debounce_key` used to identify the processed jobs and debounce them.

```ruby
class MyListener
  def self.sidekiq_options
    { debounce: { overwrite_event_name: 'my_custom_event' } }
  end

  def perform(value1, value2)
    # do something...
  end
end

# Subscribe the same class to multiple events/publishers
# If you use `overwrite_event_name` instead of the event name be `first_publisher`, `second_publisher`,
# `third_publisher` it will be `my_custom_event`
FirstPublisher.subscribe(MyListener.new)
SecondPublisher.subscribe(MyListener.new)
ThirdPublisher.subscribe(MyListener.new)
```

Under the hood this will call the `perform_in` method.

### Limitations

It's not possible to use mixed arguments.
If you have a class with a method like this `my_method(value1, email:)` and you wanna use both arguments
as debounce keys, what you should do is `debounce: { keys: [0, 1] }`.

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
