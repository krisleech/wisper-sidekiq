require 'wisper/sidekiq'

RSpec.describe Wisper::SidekiqBroadcaster do
  let(:broadcaster) { Wisper::SidekiqBroadcaster.new }
  let(:subscriber) { spy('subscriber') }
  let(:sidekiq_options) { { retry: 5, queue: :my_queue, backtrace: true } }

  describe "#broadcast" do
    before do
      Wisper::Sidekiq.configure do |config|
        config.sidekiq_options = sidekiq_options
      end
    end

    it 'configures sidekiq with options' do
      broadcaster.broadcast(subscriber, nil, :event, :args)
      expect(subscriber).to have_received(:delay).with(sidekiq_options)
    end
  end
end
