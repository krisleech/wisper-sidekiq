require 'wisper/sidekiq'

RSpec.describe Wisper::Sidekiq do
  let(:sidekiq_options) { { retry: 5, queue: :my_queue, backtrace: true } }

  describe "#configure" do
    it "should write allowed configuration" do
      Wisper::Sidekiq.configure do |config|
        config.sidekiq_options = sidekiq_options
      end
      expect(Wisper::Sidekiq.configuration.sidekiq_options).to eq sidekiq_options
    end

    it "should raise exception for non-allowed configuration" do
      expect {
        Wisper::Sidekiq.configure do |config|
          config.not_allowed = 'not allowed'
        end
      }.to raise_error(NoMethodError)
    end
  end
end