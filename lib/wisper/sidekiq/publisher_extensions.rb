module Wisper
  module Sidekiq
    module PublisherExtensions
      # Extension to automatically register subscriber classes as safe
      module SubscribeRegisterTypes
        def subscribe(listener, *args, **kargs, &block)
          Wisper::Sidekiq::Config.register_safe_types(listener)
          super
        end
      end
    end
  end

  class << self
    # Inject into Wisper.subscribe
    prepend Sidekiq::PublisherExtensions::SubscribeRegisterTypes
  end

  module Publisher
    # Inject into CustomPublisher.new.subscribe
    prepend Sidekiq::PublisherExtensions::SubscribeRegisterTypes

    module ClassMethods
      # Inject into CustomPublisher.subscribe
      prepend Sidekiq::PublisherExtensions::SubscribeRegisterTypes
    end
  end
end
