require 'spec_helper'

describe Acme::Client::JWK do
  let(:private_key) { generate_key(key_class) }

  subject { described_class.new(private_key) }

  describe described_class::RSA do
    let(:key_class) { OpenSSL::PKey::RSA }

    describe '#to_json' do
      it 'returns a String' do
        expect(subject.to_json).to be_a(String)
      end
    end

    describe '#to_h' do
      it 'returns a Hash' do
        expect(subject.to_h).to be_a(Hash)
      end
    end

    describe '#sign' do
      let(:message) { 'hello, world' }

      it 'returns a String' do
        expect(subject.sign(message)).to be_a(String)
      end
    end

    describe '#jwa_alg' do
      it 'returns a String' do
        expect(subject.jwa_alg).to be_a(String)
      end
    end

    describe '#jwt' do
      it 'generates a valid JWT' do
        jwt_s = subject.jwt(header: { 'a-header' => 'header-value' }, payload: { 'some' => 'data' })
        jwt = JSON.parse(jwt_s)
        header = JSON.parse(Base64.decode64(jwt['protected']))
        payload = JSON.parse(Base64.decode64(jwt['payload']))

        expect(header).to include('a-header' => 'header-value')
        expect(header['typ']).to eq('JWT')
        expect(header['alg']).to eq('RS256')
        expect(header['jwk']['kty']).to eq('RSA')
        expect(payload).to include('some' => 'data')
      end
    end
  end

  describe described_class::ECDSA do
    let(:key_class) { OpenSSL::PKey::EC }

    describe '#to_json' do
      it 'returns a String' do
        expect(subject.to_json).to be_a(String)
      end
    end

    describe '#to_h' do
      it 'returns a Hash' do
        expect(subject.to_h).to be_a(Hash)
      end
    end

    describe '#sign' do
      let(:message) { 'hello, world' }

      it 'returns a String' do
        expect(subject.sign(message)).to be_a(String)
      end
    end

    describe '#jwa_alg' do
      it 'returns a String' do
        expect(subject.jwa_alg).to be_a(String)
      end
    end

    describe '#jwt' do
      it 'generates a valid JWT' do
        jwt_s = subject.jwt(header: { 'a-header' => 'header-value' }, payload: { 'some' => 'data' })
        jwt = JSON.parse(jwt_s)
        header = JSON.parse(Base64.decode64(jwt['protected']))
        payload = JSON.parse(Base64.decode64(jwt['payload']))

        expect(header).to include('a-header' => 'header-value')
        expect(header['typ']).to eq('JWT')
        expect(%w(ES256 ES384 ES512)).to include(header['alg'])
        expect(header['jwk']['kty']).to eq('EC')
        expect(payload).to include('some' => 'data')
      end
    end
  end

  def generate_key(klass)
    while k = generate_private_key
      return k if k.is_a?(klass)
    end
  end
end
