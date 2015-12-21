require 'spec_helper'

describe Acme::Client::Resources::Registration do
  let(:client) { Acme::Client.new(private_key: generate_private_key) }
  let(:registration) { client.register(contact: 'mailto:info@example.com') }

  context '#agree_terms' do
    it 'send the agreement for the terms', vcr: { cassette_name: 'registration_agree_terms' } do
      expect { registration.agree_terms }.to_not raise_error
    end
  end

  context '#get_terms' do
    it 'returns the TOS term', vcr: { cassette_name: 'registration_get_terms_success' } do
      expect(registration.get_terms).to be_a(String)
    end
  end
end
