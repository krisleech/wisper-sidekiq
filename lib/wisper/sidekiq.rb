require 'wisper'
require 'sidekiq'

require 'wisper/sidekiq/version'

module Wisper
  class SidekiqBroadcaster
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def broadcast(subscriber, publisher, event, args)
      subscriber.delay(options).public_send(event, *args)
    end

    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, Proc.new { |options| SidekiqBroadcaster.new(options) }
        config.broadcaster :async,   Proc.new { |options| SidekiqBroadcaster.new(options) }
      end
    end
  end
end

Wisper::SidekiqBroadcaster.register
