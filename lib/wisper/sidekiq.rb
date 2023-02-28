require 'yaml'
require 'wisper'
require 'sidekiq'
require 'wisper/sidekiq/version'

module Wisper
  # based on Sidekiq 4.x #delay method, which is not enabled by default in Sidekiq 5.x
  # https://github.com/mperham/sidekiq/blob/4.x/lib/sidekiq/extensions/generic_proxy.rb
  # https://github.com/mperham/sidekiq/blob/4.x/lib/sidekiq/extensions/class_methods.rb

  class SidekiqBroadcaster
    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, SidekiqBroadcaster.new
        config.broadcaster :async, SidekiqBroadcaster.new
      end
    end

    class Worker
      include ::Sidekiq::Worker

      def perform(yml)
        (subscriber, event, args, debounce_key, debounce_id) = unpack_args(yml)

        # In case we are unable to pass a debounce_key AND debounce_id, this means something went wrong
        # and we should NOT prevent Wisper/Sidekiq to process the events
        if debounce_key && debounce_id
          ::Sidekiq.redis do |redis|
            # Retrieve the last saved Job ID and compare with the current debounce_id running
            last_stored_debounce_key = redis.get(debounce_key)
            # If false, this means this event being called IS NOT the last event emitted, which means we should debounce
            subscriber.public_send(event, *args) if last_stored_debounce_key == debounce_id
          end
        else
          subscriber.public_send(event, *args)
        end
      end

      private

      def unpack_args(yml)
        # yml can contain nil values, there are no problems on that
        # no reason to worry about debounce_key or debounce_id to be nil sometimes
        if Psych::VERSION.to_i >= 4
          ::YAML.unsafe_load(yml)
        else
          ::YAML.load(yml)
        end
      end
    end

    def broadcast(subscriber, publisher, event, args)
      # options include options like queue, retry, and other sidekiq_options
      original_options = sidekiq_options(subscriber)
      debounce_options = original_options[:debounce]
      # Initialize the Sidekiq::Worker object with sidekiq_options
      worker = Worker.set(original_options)

      # 1. Do we have debounce options? Yes, then we can proceed using the debounce mechanism
      if debounce_options
        # Create an unique debounce_key that will be used to identify similar jobs being scheduled during the debounce period
        debounce_key = compute_debounce_key(subscriber, event, args, debounce_options)
        # Generate an unique JOB ID before trying to schedule the job, this way we can pass this
        # ID down to the `perform` method to correctly identify the last scheduled job
        debounce_id = SecureRandom.uuid
        # By default, we expire the Redis unique identifier in 2 hours
        debounce_expire_in_seconds = debounce_options[:expire_in_seconds] || 60*60*2

        ::Sidekiq.redis do |redis|
          save_debounce_key_on_redis(redis, debounce_key, debounce_id, debounce_expire_in_seconds)
          schedule_sidekiq_job(worker, debounce_options[:in_seconds], subscriber, event, args, debounce_key: debounce_key, debounce_id: debounce_id)
        end
      # 2. If we don't then just schedule the job as normal
      else
        delay_in_seconds = original_options[:perform_in] || 0
        schedule_sidekiq_job(worker, delay_in_seconds, subscriber, event, args)
      end
    end

    def compute_debounce_key(subscriber, event, args, debounce_options)
      event_name = debounce_options.dig(:overwrite_event_name) || event
      # There is no sense of calculating the key if no arguments are passed
      return "#{subscriber}-#{event_name}-debounce" unless args[0]

      # Grab all the keys that should be used from arguments
      debounce_keys = debounce_options.dig(:keys) || []
      # Now grab the values of the arguments using the keys
      # ARGS is always an Array, that's why the need of [0]
      debounce_by_arguments = debounce_keys.map {|key| args.first[key]}
      # Group everything into a string that will be used to compound the key
      final_debounce_key = debounce_by_arguments.join('-')

      "#{subscriber}-#{event_name}-#{final_debounce_key}"
    end

    def pack_args(subscriber, event, args, debounce_key, debounce_id)
      # Even if debounce_key or debounce_id are nil, there are no problems dumping the YAML
      ::YAML.dump([subscriber, event, args, debounce_key, debounce_id])
    end

    def save_debounce_key_on_redis(redis, debounce_key, debounce_id, expire_in_seconds)
      redis.set(debounce_key, debounce_id, ex: expire_in_seconds)
    end

    def schedule_sidekiq_job(worker, debounce_in_seconds, subscriber, event, args, debounce_key: nil, debounce_id: nil)
      worker.perform_in(debounce_in_seconds, pack_args(subscriber, event, args, debounce_key, debounce_id))
    end

    def sidekiq_options(subscriber)
      subscriber.respond_to?(:sidekiq_options) ? subscriber.sidekiq_options : { perform_in: 0 }
    end
  end
end

Wisper::SidekiqBroadcaster.register
