module Wisper
  module Sidekiq
    class Config
      class << self
        attr_reader :use_unsafe_yaml

        DEFAULT_SAFE_TYPES = [
          Class,
          Symbol,
          Time,
        ].freeze

        def use_unsafe_yaml!
          @use_unsafe_yaml = true
        end

        def safe_types
          @safe_types ||= DEFAULT_SAFE_TYPES
        end

        def register_safe_types(*types)
          @safe_types ||= DEFAULT_SAFE_TYPES
          @safe_types += types
          @safe_types.flatten!
          @safe_types.uniq!
        end
      end
    end

    class << self
      def configure
        yield Config
      end
    end
  end
end
