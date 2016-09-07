require 'wisper'
require 'sidekiq'

require 'wisper/sidekiq/version'

module Wisper
  module Sidekiq

    def self.configure
      yield(configuration)
    end

    def self.configuration
      @configuration ||= Configuration.new
    end
  end

  class Configuration
    attr_accessor :sidekiq_options

    def initialize
      @sidekiq_options = {}
    end
  end

  class SidekiqBroadcaster

    def broadcast(subscriber, publisher, event, args)
      subscriber.delay(sidekiq_options).public_send(event, *args)
    end


    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, SidekiqBroadcaster.new
        config.broadcaster :async,   SidekiqBroadcaster.new
      end
    end

    private

    def sidekiq_options
      Sidekiq.configuration.sidekiq_options
    end
  end
end

Wisper::SidekiqBroadcaster.register
