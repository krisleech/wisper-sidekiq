require 'coveralls'
require 'simplecov'
require 'pry' unless ENV['CI']
require 'sidekiq/testing'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter

SimpleCov.start { add_filter 'spec/dummy_app' }

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  YAML::ENGINE.yamler = 'psych'
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 0

  config.order = :random

  Kernel.srand config.seed
end
