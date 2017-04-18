require 'wisper/sidekiq'

RSpec.describe 'configuration' do
  let(:configuration) { Wisper.configuration }

  it 'configures sidekiq as a broadcaster' do
    expect(configuration.broadcasters).to include :sidekiq
  end

  it 'configures sidekiq as default async broadcaster' do
    expect(configuration.broadcasters[:async]).to be_an_instance_of(Wisper::SidekiqBroadcaster)
  end

  it 'uses .job_options when calling delay' do
    subscriber = double(job_options: { foo: 'bar' })
    allow(subscriber).to receive(:delay).and_return(double(test: nil))

    Wisper::SidekiqBroadcaster.new.broadcast(subscriber, double, :test, [])
    expect(subscriber).to have_received(:delay).with({ foo: 'bar' })
  end
end
