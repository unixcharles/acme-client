require 'spec_helper'

describe Acme::Resources::Authorization do
  let(:client) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@example.com')
    registration.agree_terms
    client
  end

  let(:authorization) { client.authorize(domain: 'example.org')}

  context '#http01' do
    it 'returns a HTTP01 object', vcr: { cassette_name: 'authorization_http_01' }  do
      expect(authorization.http01).to be_a(Acme::Resources::Challenges::HTTP01)
    end
  end
end
