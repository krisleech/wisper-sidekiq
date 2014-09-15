require 'pry'

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
    File.delete('/Users/kris/out') if File.exists?('/Users/kris/out')
  end

  it 'performs event in a different thread' do
    expect(File.exists?('/Users/kris/out')).to be_falsey


    publisher.subscribe(Subscriber, broadcaster: Wisper::SidekiqBroadcaster.new)

    publisher.run

    sleep 2

    expect(File.exists?('/Users/kris/out')).to be_truthy

    file = File.read('/Users/kris/out')
    expect(file).to eq "pid: #{Process.gid}\n"
  end
end
