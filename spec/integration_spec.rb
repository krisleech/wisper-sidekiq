require 'wisper/sidekiq'

require_relative 'dummy_app/app'
require 'sidekiq/api'

RSpec.describe 'integration tests:' do
  let(:publisher) do
    Class.new do
      include Wisper::Publisher

      def run
        broadcast(:it_happened, 'hello, world')
      end
    end.new
  end

  before do
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
    File.delete('/tmp/shared') if File.exist?('/tmp/shared')
  end

  context 'when broadcaster is plain object' do
    it 'performs event in a different process' do
      publisher.subscribe(Subscriber, async: Wisper::SidekiqBroadcaster.new)

      publisher.run

      Timeout.timeout(10) do
        while !File.exist?('/tmp/shared')
          sleep(0.1)
        end
      end

      shared_content = File.read('/tmp/shared')
      expect(shared_content).not_to eq "pid: #{Process.pid}\n"
    end
  end

  context 'when broadcaster is async and passes options' do
    it 'performs event in a different process' do
      pending('Pending until wisper support for async options is published')

      publisher.subscribe(Subscriber, async: { queue: 'default' })

      publisher.run

      Timeout.timeout(10) do
        while !File.exist?('/tmp/shared')
          sleep(0.1)
        end
      end

      shared_content = File.read('/tmp/shared')
      expect(shared_content).not_to eq "pid: #{Process.pid}\n"
    end
  end
end
