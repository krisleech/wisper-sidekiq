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

  it 'performs event in a different process' do
    publisher.subscribe(Subscriber, async: Wisper::SidekiqBroadcaster.new)

    publisher.run

    # Note: failure here can indicate sidekiq is not running, run
    # scripts/sidekiq
    #
    Timeout.timeout(10) do
      while !File.exist?('/tmp/shared')
        sleep(0.1)
      end
    end

    shared_content = File.read('/tmp/shared')
    expect(shared_content).not_to eq "pid: #{Process.pid}\n"
  end
end
