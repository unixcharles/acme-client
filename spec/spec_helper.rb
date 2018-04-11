$LOAD_PATH.unshift File.join(__dir__, '../lib')
$LOAD_PATH.unshift File.join(__dir__, 'support')

require 'openssl'

DIRECTORY_URL = ENV['ACME_DIRECTORY_URL'] || 'https://127.0.0.1/directory'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'acme/client'

require 'rspec'
require 'vcr'
require 'webmock/rspec'

require 'asn1_helper'
require 'http_helper'
require 'retry_helper'
require 'ssl_helper'
require 'tls_helper'
require 'profile_helper' if ENV['RUBY_PROF']

# pebble use self-signed certificate
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

RSpec.configure do |c|
  c.include Asn1Helper
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
  c.default_cassette_options = { record: :once, match_requests_on: [:method, :path, :query] }
  c.allow_http_connections_when_no_cassette = false
  c.filter_sensitive_data('<DIRECTORY_URL>') { DIRECTORY_URL }
end
