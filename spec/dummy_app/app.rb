# This is loaded by Sidekiq

require 'wisper/sidekiq'
require_relative 'subscriber'

Wisper::Sidekiq.configure do |config|
  config.custom_permitted_classes = [Subscriber]
end
