require 'spec_helper'

describe Acme::Resources::Authorization do
  let(:client) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@test.com')
    registration.agree_terms
    client
  end

  let(:authorization) { client.authorize(domain: 'domain.com')}

  context '#simple_http' do
    it 'returns a SimpleHttp object', vcr: { cassette_name: 'authorization_simple_http' }  do
      expect(authorization.simple_http).to be_a(Acme::Resources::Challenges::SimpleHttp)
    end
  end
end
