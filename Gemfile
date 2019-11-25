source 'https://rubygems.org'

gemspec

gem 'bundler'
gem 'rake'
gem 'rspec'
gem 'coveralls', require: false

gem 'redis', '<= 4.0.3' if RUBY_VERSION < '2.3'

gem 'psych', platforms: :rbx

group :extras do
  gem 'rerun'
  gem 'pry-byebug'
end
