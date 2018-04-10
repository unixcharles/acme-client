require 'spec_helper'

describe Acme::Client::Resources::Challenges do
  let(:private_key) { generate_private_key }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: $directory_url)
    client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
    client
  end

  let(:order) do
    client.new_order(identifiers: [{ type: 'dns', value: 'example.com' }])
  end
  let(:authorization) { client.authorization(url: order.authorization_urls.first) }
  let(:http01) { authorization.http01 }

  context 'reload', vcr: { cassette_name: 'challenge_reload' } do
    it 'reload reload the challenge' do
      expect { http01.reload }.not_to raise_error
    end
  end

  context 'key_authorization', vcr: { cassette_name: 'challenge_key_authorization' } do
    it 'returns a key authorization' do
      token, jwk_thumbprint = http01.key_authorization.split('.')
      expect(token).to eq(http01.token)
      expect(jwk_thumbprint).to be_a(String)
    end
  end

  context 'request_validation' do
    it 'successfully verify the challenge', vcr: { cassette_name: 'challenge_verify_success' } do
      serve_once(http01.file_content) do
        expect {
          expect(http01.request_validation).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { http01.status != 'pending' }) do
            http01.reload
          end
        }.to_not raise_error

        expect(http01.status).to eq('valid')
      end
    end

    it 'fail to verify the challenge and return the status', vcr: { cassette_name: 'challenge_verify_failure' } do
      serve_once("#{http01.file_content}-oops") do
        expect {
          expect(http01.request_validation).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { http01.status != 'pending' }) do
            http01.reload
          end
        }.to_not raise_error

        expect(http01.status).to eq('invalid')
        expect(http01.error).to_not be_empty
      end
    end
  end
end
