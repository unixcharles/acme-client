require 'spec_helper'

describe Acme::Client::Resources::Directory do
  let(:private_key) { generate_private_key }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL)
    client.new_account(contact: "mailto:info@#{EXAMPLE_DOMAIN}", terms_of_service_agreed: true)
    client
  end

  let(:directory) { client.directory }

  context 'endpoint_for', vcr: { cassette_name: 'directory_endpoint_for' } do
    it { expect(directory.endpoint_for(:new_nonce)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:new_account)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:new_order)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:revoke_certificate)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:key_change)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:renewal_info)).to be_a_kind_of(URI) }

    context 'when rate limited', vcr: { cassette_name: 'directory_ratelimit' } do
      it do
        expect {
          directory.endpoint_for(:new_order)
        }.to raise_error(Acme::Client::Error::RateLimited)
      end
    end
  end

  context 'meta', vcr: { cassette_name: 'directory_meta' } do
    it { expect(directory.meta).to be_a(Hash) }
    it { expect(directory.terms_of_service).to be_a(String) }
    it { expect(directory.external_account_required).to be nil }
    it { expect(directory.profiles).to be_a_kind_of(Hash) }
  end
end
