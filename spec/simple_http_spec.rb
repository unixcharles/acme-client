require 'spec_helper'

describe Acme::Resources::Challenges::SimpleHttp do
  let(:simple_http) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@test.com')
    registration.agree_terms
    authorization = client.authorize(domain: "test#{rand(10*10)}.testdomain.com")
    simple_http = authorization.simple_http
    simple_http.tls = false
    simple_http
  end

  context '#verify' do
    it 'successfully verify the challenge', vcr: { cassette_name: 'simple_http_verify_success' } do
      serve_once(simple_http.file_content) do
        expect {
          expect(simple_http.request_verification).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { simple_http.status != 'pending' }) do
            simple_http.verify_status
          end
        }.to_not raise_error

        expect(simple_http.status).to eq('valid')
      end
    end

    it 'fail to verify the challenge and return the status', vcr: { cassette_name: 'simple_http_verify_failure' } do
      serve_once("#{simple_http.file_content}-oops") do
        expect {
          expect(simple_http.request_verification).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { simple_http.status != 'pending' }) do
            simple_http.verify_status
          end
        }.to_not raise_error

        expect(simple_http.status).to eq('invalid')
        expect(simple_http.error).to_not be_empty
      end
    end
  end
end
