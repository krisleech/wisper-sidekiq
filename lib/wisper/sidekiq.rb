require 'yaml'
require 'wisper'
require 'sidekiq'
require 'wisper/sidekiq/version'
require 'wisper/sidekiq/config'
require 'wisper/sidekiq/publisher_extensions'

module Wisper

  # based on Sidekiq 4.x #delay method, which is not enabled by default in Sidekiq 5.x
  # https://github.com/mperham/sidekiq/blob/4.x/lib/sidekiq/extensions/generic_proxy.rb
  # https://github.com/mperham/sidekiq/blob/4.x/lib/sidekiq/extensions/class_methods.rb

  class SidekiqBroadcaster
    class Worker
      include ::Sidekiq::Worker

      def perform(yml)
        (subscriber, event, args, kwargs) =
          if Wisper::Sidekiq::Config.use_unsafe_yaml
            unsafe_load_method = Psych::VERSION.to_i >= 4 ? :unsafe_load : :load
            ::YAML.send(unsafe_load_method, yml)
          else
            ::YAML.safe_load(yml, permitted_classes: Wisper::Sidekiq::Config.safe_types, aliases: true)
          end

        # Prevents jobs enqueued with old signature from failing
        kwargs ||= {}

        subscriber.public_send(event, *args, **kwargs)
      end
    end

    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, SidekiqBroadcaster.new
        config.broadcaster :async,   SidekiqBroadcaster.new
      end
    end

    def broadcast(subscriber, publisher, event, *args, **kwargs)
      options = sidekiq_options(subscriber)
      schedule_options = sidekiq_schedule_options(subscriber, event)
      client_class = options[:client_class] || options["client_class"]

      with_client_class(client_class) do
        Worker.set(options).perform_in(
          schedule_options.fetch(:delay, 0),
          ::YAML.dump([subscriber, event, args, kwargs])
        )
      end
    end

    private

    def sidekiq_options(subscriber)
      subscriber.respond_to?(:sidekiq_options) ? subscriber.sidekiq_options : {}
    end

    # Sidekiq::Job#build_client checks Thread.current[:sidekiq_client_class]
    # before falling back to the worker's class-level sidekiq_options["client_class"].
    # The internal Worker is shared across all subscribers, so per-subscriber
    # client_class selection is routed through the thread-local instead of
    # mutating the shared Worker class.
    def with_client_class(client_class)
      return yield if client_class.nil?

      previous = Thread.current[:sidekiq_client_class]
      Thread.current[:sidekiq_client_class] = client_class
      begin
        yield
      ensure
        Thread.current[:sidekiq_client_class] = previous
      end
    end

    def sidekiq_schedule_options(subscriber, event)
      return {} unless subscriber.respond_to?(:sidekiq_schedule_options)

      options = subscriber.sidekiq_schedule_options

      if options.has_key?(event.to_sym)
        delay_option(options[event.to_sym])
      else
        delay_option(options)
      end
    end

    def delay_option(options)
      return {} unless options.key?(:perform_in) || options.key?(:perform_at)

      { delay: options[:perform_in] || options[:perform_at] }
    end
  end
end

Wisper::SidekiqBroadcaster.register
