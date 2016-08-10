require 'spec_helper'

describe Acme::Client::Crypto do
  let(:private_key) { generate_private_key }
  subject(:crypto) { Acme::Client::Crypto.new(private_key) }

  it 'returns the private key' do
    expect(crypto.private_key).to be(private_key)
  end

  context '#generate_signed_jws' do
    it 'signs the data' do
      signed_jws = crypto.generate_signed_jws(header: { 'a-header' => 'header-value' }, payload: { 'some' => 'data' })
      jws = JSON.parse(signed_jws)
      header = JSON.parse(Base64.decode64(jws['protected']))
      payload = JSON.parse(Base64.decode64(jws['payload']))

      expect(header).to include('a-header' => 'header-value')
      expect(header['typ']).to eq('JWT')
      expect(header['alg']).to eq('RS256')
      expect(header['jwk']['kty']).to eq('RSA')
      expect(payload).to include('some' => 'data')
    end
  end
end
