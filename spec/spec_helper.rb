$LOAD_PATH.unshift File.join(__dir__, '../lib')
$LOAD_PATH.unshift File.join(__dir__, 'support')

require 'acme/client'

require 'rspec'
require 'vcr'
require 'webmock/rspec'

require 'http_helper'
require 'retry_helper'
require 'ssl_helper'
require 'tls_helper'
require 'profile_helper' if ENV['RUBY_PROF']

RSpec.configure do |c|
  c.include HttpHelper
  c.include TlsHelper
  c.include RetryHelper
  c.include SSLHelper
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
  c.hook_into :webmock
  c.ignore_localhost = false
  c.default_cassette_options = { record: :once }
  c.allow_http_connections_when_no_cassette = false
end
