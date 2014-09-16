# Wisper::Sidekiq

Provides Wisper with async event publishing using Sidekiq.

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
