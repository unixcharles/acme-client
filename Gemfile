source 'https://rubygems.org'

gemspec

if faraday_version = ENV['FARADAY_VERSION']
  gem 'faraday', faraday_version
end

group :development, :test do
  gem 'pry'
  gem 'rubocop', '~> 0.49.0'
  gem 'ruby-prof', require: false
end
