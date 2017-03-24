require 'wisper/sidekiq'

RSpec.describe 'configuration' do
  let(:configuration) { Wisper.configuration }

  it 'configures sidekiq as a broadcaster' do
    expect(configuration.broadcasters).to include :sidekiq
  end

  it 'configures sidekiq as default callable async broadcaster' do
    expect(configuration.broadcasters[:async]).to be_an_instance_of(Proc)
    expect(configuration.broadcasters[:async].call).to be_an_instance_of(Wisper::SidekiqBroadcaster)
  end
end
