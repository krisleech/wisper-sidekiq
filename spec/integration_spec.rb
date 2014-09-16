require 'wisper/sidekiq'

require_relative './dummy_app/app'
require 'sidekiq/api'

class Wisper::SidekiqBroadcaster
  def broadcast(subscriber, publisher, event, args)
    subscriber.delay.public_send(event, args)
  end
end

RSpec.describe 'integration tests:' do
  let(:sidekiq_queue) { Sidekiq::Queue.new }
  let(:publisher) do
    Class.new do
      include Wisper::Publisher

      def run
        broadcast(:it_happened, 'hello, world')
      end
    end.new
  end

  before do
    sidekiq_queue.clear
    Sidekiq::RetrySet.new.clear
    File.delete('/tmp/shared') if File.exist?('/tmp/shared')
  end

  it 'performs event in a different process' do
    publisher.subscribe(Subscriber, broadcaster: Wisper::SidekiqBroadcaster.new)

    publisher.run

    Timeout.timeout(2) do
      while !File.exist?('/tmp/shared')
        sleep(0.1)
      end
    end

    shared_content = File.read('/tmp/shared')
    expect(shared_content).not_to eq "pid: #{Process.pid}\n"
  end
end
