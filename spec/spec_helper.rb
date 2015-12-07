$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../support', __FILE__)

require 'acme-client'

require 'rspec'
require 'vcr'

require 'http_helper'
require 'retry_helper'
require 'ssl_helper'

RSpec.configure do |c|
  c.include HttpHelper
  c.include RetryHelper
  c.include SSLHelper
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
  c.hook_into :webmock
  c.ignore_localhost = false
  c.default_cassette_options = {record: :new_episodes}
  c.allow_http_connections_when_no_cassette = false
end
