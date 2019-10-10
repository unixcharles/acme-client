require 'spec_helper'

describe Acme::Client::Resources::Directory do
  let(:directory) { Acme::Client::Resources::Directory.new(DIRECTORY_URL, {}) }

  context 'endpoint_for', vcr: { cassette_name: 'directory_endpoint_for' } do
    it { expect(directory.endpoint_for(:new_nonce)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:new_account)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:new_order)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:revoke_certificate)).to be_a_kind_of(URI) }
    it { expect(directory.endpoint_for(:key_change)).to be_a_kind_of(URI) }
  end

  context 'meta', vcr: { cassette_name: 'directory_meta' } do
    it { expect(directory.meta).to be_a(Hash) }
    it { expect(directory.terms_of_service).to be_a(String) }
    it { expect(directory.external_account_required).to be_nil }
  end
end
