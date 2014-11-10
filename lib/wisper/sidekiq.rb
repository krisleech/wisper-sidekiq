require 'wisper'
require 'sidekiq'

require 'wisper/sidekiq/version'

module Wisper
  class SidekiqBroadcaster
    def broadcast(subscriber, publisher, event, args)
      options = subscriber.respond_to?(:job_options) ? subscriber.job_options : {}
      subscriber.delay(options).public_send(event, *args)
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
