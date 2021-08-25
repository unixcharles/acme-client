source 'https://rubygems.org'

gemspec

if faraday_version = ENV['FARADAY_VERSION']
  gem 'faraday', faraday_version
end

group :development, :test do
  gem 'pry'
  gem 'rubocop', '~> 0.49.0'
  gem 'ruby-prof', require: false

  if Gem::Version.new(RUBY_VERSION) <= Gem::Version.new('2.2.2')
    gem 'activesupport', '~> 4.2.6'
  end
end
