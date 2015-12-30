require 'spec_helper'

describe Acme::Client::Resources::Authorization do
  let(:client) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@example.com')
    registration.agree_terms
    client
  end

  let(:authorization) { client.authorize(domain: 'example.org') }

  context '#http01' do
    it 'returns a HTTP01 object', vcr: { cassette_name: 'authorization' } do
      expect(authorization.http01).to be_a(Acme::Client::Resources::Challenges::HTTP01)
    end
  end

  context '#dns01' do
    it 'returns a DNS01 object', vcr: { cassette_name: 'authorization' } do
      expect(authorization.dns01).to be_a(Acme::Client::Resources::Challenges::DNS01)
    end
  end
end
