require 'wisper/sidekiq'

RSpec.describe Wisper::SidekiqBroadcaster do
  class PublisherUnderTest
    include Wisper::Publisher

    def run
      broadcast(:it_happened)
    end
  end

  class RegularSubscriberUnderTest
    def self.it_happened
    end
  end

  class CustomizedSubscriberUnderTest
    def self.it_happened
    end

    def self.sidekiq_options
      { queue: "my_queue" }
    end
  end

  let(:publisher) { PublisherUnderTest.new }

  before { Sidekiq::Testing.fake! }
  after { Sidekiq::Testing.disable! }

  describe '#broadcast' do
    it 'schedules a sidekiq job' do
      publisher.subscribe(RegularSubscriberUnderTest, async: described_class.new)

      expect { publisher.run }
        .to change(Sidekiq::Queues["default"], :size).by(1)
    end

    it 'can respect custom sidekiq_options' do
      publisher.subscribe(CustomizedSubscriberUnderTest, async: described_class.new)

      expect { publisher.run }
        .to change(Sidekiq::Queues["my_queue"], :size).by(1)
    end
  end
end