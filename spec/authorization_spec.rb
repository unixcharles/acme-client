# frozen_string_literal: true

require 'spec_helper'

describe Acme::Client::Resources::Authorization do
  let(:private_key) { generate_private_key }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL)
    client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
    client
  end

  let(:order) do
    client.new_order(identifiers: [{ type: 'dns', value: 'example.com' }])
  end
  let(:authorization) { client.authorization(url: order.authorization_urls.first) }

  context 'deactivate' do
    it 'successfully deactive the authorization', vcr: { cassette_name: 'authorization_deactivate' } do
      expect(authorization.status).to eq('pending')
      expect { authorization.deactivate }.not_to raise_error
      expect(authorization.status).to eq('deactivated')
    end
  end

  context 'challenges' do
    it 'returns the challenges', vcr: { cassette_name: 'authorization_challenges' } do
      expect(authorization.challenges).to all(be_kind_of(Acme::Client::Resources::Challenges::Base))
    end

    it 'returns the HTTP challenge', vcr: { cassette_name: 'authorization_http_challenge' } do
      expect(authorization.http).to be_a(Acme::Client::Resources::Challenges::HTTP01)
    end

    it 'returns the DNS challenge', vcr: { cassette_name: 'authorization_dns_challenge' } do
      expect(authorization.dns).to be_a(Acme::Client::Resources::Challenges::DNS01)
    end
  end

  context 'reload' do
    it 'successfully reload the authorization', vcr: { cassette_name: 'authorization_reload' } do
      expect { authorization.reload }.not_to raise_error
    end
  end
end
