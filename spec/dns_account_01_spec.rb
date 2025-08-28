# frozen_string_literal: true

require 'spec_helper'

describe Acme::Client::Resources::Challenges::DNSAccount01 do
  let(:private_key) { generate_private_key }
  let(:kid) { 'https://example.com/acme/acct/ExampleAccount' }
  let(:client) do
    Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL, kid: kid)
  end
  let(:attributes) do
    { status: 'pending', url: 'https://example.com/foo/bar', token: 'example_token' }
  end
  let(:dns_account_01) do
    Acme::Client::Resources::Challenges::DNSAccount01.new(client, **attributes)
  end

  it 'returns the account specific record name' do
    expect(dns_account_01.record_name).to eq('_ujmmovf2vn55tgye._acme-challenge')
  end

  it { expect(dns_account_01.record_type).to eq('TXT') }

  it 'returns the digest of the key authorization' do
    key_authorization = "#{attributes[:token]}.#{client.jwk.thumbprint}"
    expected = Acme::Client::Util.urlsafe_base64(OpenSSL::Digest::SHA256.digest(key_authorization))
    expect(dns_account_01.record_content).to eq(expected)
  end
end
