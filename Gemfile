source 'https://rubygems.org'
gemspec

group :development, :test do
  gem 'pry'
  gem 'rubocop', '0.36.0'
  gem 'ruby-prof', require: false

  if Gem::Version.new(RUBY_VERSION) <= Gem::Version.new('2.2.2')
    gem 'activesupport', '~> 4.2.6'
  end
end
