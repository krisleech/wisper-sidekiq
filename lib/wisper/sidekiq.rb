require 'wisper'
require 'sidekiq'

require 'wisper/sidekiq/version'

module Wisper
  class SidekiqBroadcaster
    def broadcast(subscriber, publisher, event, args)
      method = subscriber.respond_to?(:sidekiq_delay) ? :sidekiq_delay : :delay
      subscriber.send(method).public_send(event, *args)
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
