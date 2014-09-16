require 'wisper/sidekiq/version'

require 'wisper'
require 'sidekiq'

module Wisper
  class SidekiqBroadcaster
    def broadcast(subscriber, publisher, event, args)
      subscriber.delay.public_send(event, args)
    end
  end
end

