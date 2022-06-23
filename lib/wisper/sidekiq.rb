require 'yaml'
require 'wisper'
require 'sidekiq'
require 'wisper/sidekiq/version'

module Wisper

  # based on Sidekiq 4.x #delay method, which is not enabled by default in Sidekiq 5.x
  # https://github.com/mperham/sidekiq/blob/4.x/lib/sidekiq/extensions/generic_proxy.rb
  # https://github.com/mperham/sidekiq/blob/4.x/lib/sidekiq/extensions/class_methods.rb

  class SidekiqBroadcaster
    class Worker
      include ::Sidekiq::Worker

      def perform(yml)
        (subscriber, event, args) = ::YAML.unsafe_load(yml)
        subscriber.public_send(event, *args)
      end
    end

    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, SidekiqBroadcaster.new
        config.broadcaster :async,   SidekiqBroadcaster.new
      end
    end

    def broadcast(subscriber, publisher, event, args)
      options = sidekiq_options(subscriber)
      schedule_options = sidekiq_schedule_options(subscriber, event)

      Worker.set(options).perform_in(
        schedule_options.fetch(:delay, 0),
        ::YAML.dump([subscriber, event, args])
      )
    end

    private

    def sidekiq_options(subscriber)
      subscriber.respond_to?(:sidekiq_options) ? subscriber.sidekiq_options : {}
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
