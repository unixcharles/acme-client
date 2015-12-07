$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'acme-client'

require 'rspec'
require 'vcr'

require 'webrick'

module TestHelper
  def generate_private_key
    OpenSSL::PKey::RSA.new(2048)
  rescue OpenSSL::PKey::RSAError # Try again
    sleep(0.05)
    OpenSSL::PKey::RSA.new(2048)
  end

  def generate_csr(common_name, private_key)
    request = OpenSSL::X509::Request.new
    request.subject = OpenSSL::X509::Name.new([
      ['CN', common_name, OpenSSL::ASN1::UTF8STRING]
    ])

    request.public_key = private_key.public_key
    request.sign(private_key, OpenSSL::Digest::SHA256.new)
    request
  end

  def retry_until(condition:, retry_count: 3, wait: 0.25)
    count = 0
    until condition.call
      yield
      count =+ 1
      raise 'timed out' if count > retry_count
    end
  end

  def serve_once(body)
    if VCR.real_http_connections_allowed?
      dev_null = Logger.new(StringIO.new)
      server = WEBrick::HTTPServer.new(:Port => 5002, :Logger => dev_null, :AccessLog => dev_null)

      thread = Thread.new do
        server.mount_proc('/') do |_, response|
          response.body = body
        end
        server.start
      end
    end

    yield
  ensure
    if VCR.real_http_connections_allowed?
      server.shutdown
      thread.join(5)
    end
  end
end

RSpec.configure do |c|
  c.include TestHelper
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
  c.hook_into :webmock
  c.ignore_localhost = false
  c.default_cassette_options = {record: :new_episodes}
  c.allow_http_connections_when_no_cassette = false
end
