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
        (subscriber, event, args) = ::YAML.load(yml)
        subscriber.public_send(event, *args)
      end
    end

    def broadcast(subscriber, publisher, event, args)
      Worker.perform_async(::YAML.dump([subscriber, event, args]))
    end

    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, SidekiqBroadcaster.new
        config.broadcaster :async,   SidekiqBroadcaster.new
      end
    end
  end
end

Wisper::SidekiqBroadcaster.register
