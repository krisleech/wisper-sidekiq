require 'wisper/sidekiq'

RSpec.describe Wisper::SidekiqBroadcaster do
  class NormalPublisher
    include Wisper::Publisher

    def run(args = nil)
      broadcast(:it_happened, args)
    end
  end

  class AnotherPublisher
    include Wisper::Publisher

    def run(args = nil)
      broadcast(:it_happened, args)
      broadcast(:another_happened, args)
    end
  end

  class RegularSubscriberUnderTest
    def self.it_happened(*_)
    end
  end

  class CustomizedWithCustomQueue
    def self.it_happened(*_)
    end

    def self.sidekiq_options
      { queue: "custom_queue" }
    end
  end

  class CustomizedSubscriberWithPerformInOptions
    def self.it_happened(*_)
    end

    def self.sidekiq_options
      { perform_in: 5 }
    end
  end

  class CustomizedSubscriberWithWrongSidekiqOptions
    def self.it_happened(*_)
    end

    def self.sidekiq_options
      { perform_in: 'not a number', delay: 5 }
    end
  end

  class CustomizedSubscriberWithDebounceOptions
    def self.it_happened(*_)
      'I was processed!'
    end

    def self.sidekiq_options
      { queue: 'debounce_queue', debounce: { in_seconds: 15, keys: [:user_id] } }
    end
  end

  class CustomizedSubscriberWithNumberedArguments
    def self.it_happened(*_)
      'I was processed!'
    end

    def self.sidekiq_options
      { queue: 'numbered_queue', debounce: { in_seconds: 15, keys: [0, 1] } }
    end
  end

  class CustomizedSubscriberWithoutOverwriteEventName
    def self.it_happened(*_)
      'Processing this first'
    end

    def self.another_happened(*_)
      'Processing this by last'
    end

    def self.sidekiq_options
      { queue: 'custom_queue', debounce: { in_seconds: 15 } }
    end
  end

  class CustomizedSubscriberWithOverwriteEventName
    def self.it_happened(*_)
      'Processing this first'
    end

    def self.another_happened(*_)
      'Processing this by last'
    end

    def self.sidekiq_options
      { queue: 'custom_queue', debounce: { in_seconds: 15, overwrite_event_name: 'my_custom_event' } }
    end
  end

  let(:publisher) { NormalPublisher.new }
  let(:another_publisher) { AnotherPublisher.new }

  before do
    Sidekiq::Queues.clear_all
    Sidekiq::Testing.fake!
  end

  after { Sidekiq::Testing.disable! }

  describe '#broadcast' do
    it 'schedules a regular sidekiq job' do
      publisher.subscribe(RegularSubscriberUnderTest, async: described_class.new)

      expect { publisher.run }.to change(Sidekiq::Queues["default"], :size).by(1)
      expect { publisher.run }.not_to change { Sidekiq::Queues["default"].select{|job| job.key?('at')}.size }
    end

    it 'schedules a job to run with perform_in options' do
      publisher.subscribe(CustomizedSubscriberWithPerformInOptions, async: described_class.new)

      expect { publisher.run }.to change(Sidekiq::Queues["default"], :size).by(1)
      expect { publisher.run }.to change { Sidekiq::Queues["default"].select{|job| job.key?('at')}.size }.by(1)
    end

    it 'can respect custom sidekiq_options' do
      publisher.subscribe(CustomizedWithCustomQueue, async: described_class.new)

      expect { publisher.run }.to change(Sidekiq::Queues["custom_queue"], :size).by(1)
    end

    it 'passing wrong perform_in options should schedule a regular job' do
      publisher.subscribe(CustomizedSubscriberWithWrongSidekiqOptions, async: described_class.new)

      expect { publisher.run }.to change(Sidekiq::Queues["default"], :size).by(1)
      expect { publisher.run }.not_to change { Sidekiq::Queues["default"].select{|job| job.key?('at')}.size }
    end

    it 'passing debounce options should work as normal and not prevent multiple jobs to schedule' do
      publisher.subscribe(CustomizedSubscriberWithDebounceOptions, async: described_class.new)

      # Debouncing should not prevent jobs to schedule, only to be executed multiple times
      expect { publisher.run }.to change { Sidekiq::Queues["debounce_queue"].select{|job| job.key?('at')}.size }.by(1)
      expect { publisher.run }.to change { Sidekiq::Queues["debounce_queue"].select{|job| job.key?('at')}.size }.by(1)
      expect { publisher.run }.to change { Sidekiq::Queues["debounce_queue"].select{|job| job.key?('at')}.size }.by(1)
    end

    context 'when provides subscriber with args' do
      let(:subscriber) { RegularSubscriberUnderTest }
      let(:event) { 'it_happened' }
      let(:args) { { user_id: 1, email: 'joe@doe.com' } }

      subject(:broadcast_event) { described_class.new.broadcast(subscriber, nil, event, args) }

      it 'subscriber receives event with corrects args' do
        expect(RegularSubscriberUnderTest).to receive(event).with(*args)

        Sidekiq::Testing.inline! { broadcast_event }
      end
    end

    context 'when provides subscriber with debouncing capabilities' do
      let(:subscriber) { CustomizedSubscriberWithDebounceOptions }
      let(:event) { 'it_happened' }
      let(:args) { { user_id: 1, email: 'joe@doe.com' } }
      let(:different_args) { { user_id: 2, email: 'joe@doe.com' } }
      let(:numbered_args) { [1, 23, user_id: 3, email: 'joe@doe.com'] }

      before { Sidekiq::Queues.clear_all }

      it 'when sidekiq starts processing should only move forward the last enqueued job' do
        # First lets schedule a bunch of jobs with same information
        publisher.subscribe(CustomizedSubscriberWithDebounceOptions, async: described_class.new)
        publisher.run
        expect(Sidekiq::Queues["debounce_queue"].count).to be(1)
        publisher.run
        expect(Sidekiq::Queues["debounce_queue"].count).to be(2)
        publisher.run
        expect(Sidekiq::Queues["debounce_queue"].count).to be(3)

        # The test here is to check if ONLY the last job was processed and the others were debounced (returned nil)
        Sidekiq::Testing.inline! do
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][0]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][1]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][2]['args'][0])).to eq('I was processed!')
        end
      end

      it 'when enqueuing same jobs with different arguments should process all' do
        # First lets schedule a bunch of jobs with same information
        publisher.subscribe(CustomizedSubscriberWithDebounceOptions, async: described_class.new)
        publisher.subscribe(CustomizedSubscriberWithDebounceOptions, async: described_class.new)
        publisher.run(args)
        expect(Sidekiq::Queues["debounce_queue"].count).to be(2)
        publisher.run(different_args)
        expect(Sidekiq::Queues["debounce_queue"].count).to be(4)

        # The test here is to check if ONLY the last job was processed and the others were debounced (returned nil)
        Sidekiq::Testing.inline! do
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][0]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][1]['args'][0])).to eq('I was processed!')
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][2]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['debounce_queue'][3]['args'][0])).to eq('I was processed!')
        end
      end

      it 'when multiple publisher broadcast to same class and you do not use custom event name all subscriptions should be treated individually' do
        # First lets schedule a bunch of jobs with same information
        publisher.subscribe(CustomizedSubscriberWithoutOverwriteEventName, async: described_class.new)
        publisher.subscribe(CustomizedSubscriberWithoutOverwriteEventName, async: described_class.new)
        publisher.run(numbered_args)

        another_publisher.subscribe(CustomizedSubscriberWithoutOverwriteEventName, async: described_class.new)
        another_publisher.subscribe(CustomizedSubscriberWithoutOverwriteEventName, async: described_class.new)
        another_publisher.run(numbered_args)

        # another_publisher invokes two methods, that's why the counting is 6
        expect(Sidekiq::Queues["custom_queue"].count).to be(6)

        # The test here is to check if ONLY the last job was processed and the others were debounced (returned nil)
        Sidekiq::Testing.inline! do
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][0]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][1]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][2]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][3]['args'][0])).to eq('Processing this first')
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][4]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][5]['args'][0])).to eq('Processing this by last')
        end
      end

      it 'when multiple publisher broadcast to same class should debounce if using custom event name' do
        # First lets schedule a bunch of jobs with same information
        publisher.subscribe(CustomizedSubscriberWithOverwriteEventName, async: described_class.new)
        publisher.subscribe(CustomizedSubscriberWithOverwriteEventName, async: described_class.new)
        publisher.run(numbered_args)

        another_publisher.subscribe(CustomizedSubscriberWithOverwriteEventName, async: described_class.new)
        another_publisher.subscribe(CustomizedSubscriberWithOverwriteEventName, async: described_class.new)
        another_publisher.run(numbered_args)

        # another_publisher invokes two methods, that's why the counting is 6
        expect(Sidekiq::Queues["custom_queue"].count).to be(6)

        # The test here is to check if ONLY the last job was processed and the others were debounced (returned nil)
        Sidekiq::Testing.inline! do
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][0]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][1]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][2]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][3]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][4]['args'][0])).to be_nil
          expect(Wisper::SidekiqBroadcaster::Worker.new.perform(Sidekiq::Queues['custom_queue'][5]['args'][0])).to eq('Processing this by last')
        end
      end
    end
  end
end
