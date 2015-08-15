require 'spec_helper'

describe Acme::Resources::Registration do
  let(:client) { Acme::Client.new(private_key: generate_private_key) }
  let(:registration) { client.register(contact: 'mailto:info@test.com') }

  context '#agree_terms' do
    it 'send the agreement for the terms' do
      expect { registration.agree_terms }.to_not raise_error
    end
  end

  context '#get_terms' do
    xit 'returns the TOS term', vcr: { cassette_name: 'registration_get_terms_success' } do
      registration = Acme::Resources::Registration.new(client, response)
    end
  end
end
