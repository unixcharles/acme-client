require 'spec_helper'

describe Acme::Client::Crypto do
  let(:private_key) { generate_private_key }
  subject(:crypto) { Acme::Client::Crypto.new(private_key) }

  context '#jwk' do
    it 'is a JWK::Base subclass' do
      expect(subject.jwk).to be_a(Acme::Client::JWK::Base)
    end
  end

  context '#generate_signed_jws' do
    it 'signs the data' do
      signed_jws = crypto.generate_signed_jws(header: { 'a-header' => 'header-value' }, payload: { 'some' => 'data' })
      jws = JSON.parse(signed_jws)
      header = JSON.parse(Base64.decode64(jws['protected']))
      payload = JSON.parse(Base64.decode64(jws['payload']))

      expect(header).to include('a-header' => 'header-value')
      expect(header['typ']).to eq('JWT')
      expect(%w(RS256 ES256 ES384 ES512)).to include(header['alg'])
      expect(%w(RSA EC)).to include(header['jwk']['kty'])
      expect(payload).to include('some' => 'data')
    end
  end
end
