require 'wisper/sidekiq'

require_relative 'dummy_app/app'
require 'sidekiq/api'

RSpec.describe 'integration tests:' do
  let(:publisher) do
    Class.new do
      include Wisper::Publisher

      def run
        broadcast(:it_happened, { hello: 'world' })
      end
    end.new
  end

  let(:shared_content) { File.read('/tmp/shared') }

  def ensure_sidekiq_was_running
    Timeout.timeout(10) do
      while !File.exist?('/tmp/shared')
        sleep(0.1)
      end
    end
  end

  before do
    Sidekiq::Testing.disable!
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
    File.delete('/tmp/shared') if File.exist?('/tmp/shared')
  end

  it 'performs event in a different process' do
    publisher.subscribe(Subscriber, async: Wisper::SidekiqBroadcaster.new)
    publisher.run
    ensure_sidekiq_was_running

    expect(shared_content).not_to include("pid: #{Process.pid}\n")
  end

  it 'performs event' do
    publisher.subscribe(Subscriber, async: Wisper::SidekiqBroadcaster.new)
    publisher.run
    ensure_sidekiq_was_running

    expect(shared_content).to include('{:hello=>"world"}')
  end
end
