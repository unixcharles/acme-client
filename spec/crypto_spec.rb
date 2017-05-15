require 'spec_helper'

describe Acme::Client::Crypto do
  let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:dsa_key) { OpenSSL::PKey::DSA.new(2048) }
  let(:p192_key) { Acme::Client::CertificateRequest::ECKeyPatch.new('prime192v3').tap(&:generate_key) }
  let(:p256_key) { Acme::Client::CertificateRequest::ECKeyPatch.new('prime256v1').tap(&:generate_key) }
  let(:p384_key) { Acme::Client::CertificateRequest::ECKeyPatch.new('secp384r1').tap(&:generate_key) }
  let(:p521_key) { Acme::Client::CertificateRequest::ECKeyPatch.new('secp521r1').tap(&:generate_key) }
  let(:private_key) { generate_private_key }
  let(:jwk) { subject.jwk }

  subject(:crypto) { Acme::Client::Crypto.new(private_key) }

  context '.from_jwk' do
    it 'works' do
      expect(described_class.from_jwk(jwk).jwk).to eq(jwk)
    end
  end

  context '#initialize' do
    it 'accepts a RSA key' do
      expect {
        described_class.new(rsa_key)
      }.not_to raise_error
    end

    it 'accepts a prime256v1 key' do
      expect {
        described_class.new(p256_key)
      }.not_to raise_error
    end

    it 'accepts a secp384r1 key' do
      expect {
        described_class.new(p384_key)
      }.not_to raise_error
    end

    it 'accepts a secp521r1 key' do
      expect {
        described_class.new(p521_key)
      }.not_to raise_error
    end

    it 'raises ArgumentError for other curves' do
      expect {
        described_class.new(p192_key)
      }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError for other algorithms' do
      expect {
        described_class.new(dsa_key)
      }.to raise_error(ArgumentError)
    end
  end

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
      expect(header['alg']).to eq(subject.jwk.jwa_alg)
      expect(%w(RSA EC)).to include(header['jwk']['kty'])
      expect(payload).to include('some' => 'data')
    end
  end
end
