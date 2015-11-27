require 'spec_helper'

describe Acme::Resources::Challenges::HTTP01 do
  let(:http01) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@test.com')
    registration.agree_terms
    authorization = client.authorize(domain: "test#{rand(10*10)}.testdomain.com")
    http01 = authorization.http01
    http01
  end

  context '#verify' do
    it 'successfully verify the challenge', vcr: { cassette_name: 'http01_verify_success' } do
      serve_once(http01.file_content) do
        expect {
          expect(http01.request_verification).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { http01.status != 'pending' }) do
            http01.verify_status
          end
        }.to_not raise_error

        expect(http01.status).to eq('valid')
      end
    end

    it 'fail to verify the challenge and return the status', vcr: { cassette_name: 'http01_verify_failure' } do
      serve_once("#{http01.file_content}-oops") do
        expect {
          expect(http01.request_verification).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { http01.status != 'pending' }) do
            http01.verify_status
          end
        }.to_not raise_error

        expect(http01.status).to eq('invalid')
        expect(http01.error).to_not be_empty
      end
    end
  end
end
