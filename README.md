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

### YAML permitted classes

The gem internally uses YAML serialization/deserialization to pass your event data and subscribers to a sidekiq worker through redis.

By default, for security reasons, only a few basic classes like `String` or `Array` are permitted for deserialization.

If you are using custom types as your event data, you might run into
```
Psych::DisallowedClass:
   Tried to load unspecified class: MyEventData1
```

In that case, you can explicitly allow custom types using

```ruby
Wisper::Sidekiq.configure do |config|
  config.register_safe_types(MyEventData1, MyEventData2)
end
```

Alternatively, you can opt-in for unsafe YAML loading that allows the deserialization of all classes using

```ruby
Wisper::Sidekiq.configure do |config|
  config.use_unsafe_yaml!
end
```

Keep in mind that doing this can lead to [RCE vulneraibility](https://staaldraad.github.io/post/2019-03-02-universal-rce-ruby-yaml-load/) if an unauthorised actor gets the write access to your redis server.

### Passing down sidekiq options

In order to define custom [sidekiq_options](https://github.com/mperham/sidekiq/wiki/Advanced-Options#workers) you can add `sidekiq_options` class method in your subscriber definition - those options will be passed to Sidekiq's `set` method just before scheduling the asynchronous worker.

### Passing down schedule options

In order be able to schedule jobs to be run in the future following [Scheduled Jobs](https://github.com/mperham/sidekiq/wiki/Scheduled-Jobs) you can add `sidekiq_schedule_options` class method in your subscriber definition - those options will be passed to Sidekiq's `perform_in` method when the worker is called.

This feature is not as powerful as Sidekiq's API that allows you to set this on every job enqueue, in this case you're able to set this for the whole listener class like:
```ruby
class MyListener
  #...

  def self.sidekiq_schedule_options
    { perform_in: 5 }
  end

  #...
end
```
Or you can set this per event (method called on the listener), like so:
```ruby
class MyListener
  #...

  def self.sidekiq_schedule_options
    { event_name: { perform_in: 5 } }
  end

  def self.event_name
    #...
  end

  #...
end
```
In both cases the `perform_at` option is also available.

## Compatibility

The same Ruby versions as Sidekiq are officially supported, but it should work
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
