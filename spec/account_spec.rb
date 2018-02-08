require 'spec_helper'

describe Acme::Client::Resources::Account do
  let(:client) { Acme::Client.new(private_key: generate_private_key, endpoint: 'https://acme-staging-v02.api.letsencrypt.org', directory_uri: '/directory') }
  let(:account) { client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true) }

  context 'account' do
    it 'send the agreement for the terms', vcr: { cassette_name: 'registration_agree_terms' } do
      account
    end
  end
end
