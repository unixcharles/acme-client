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
end
