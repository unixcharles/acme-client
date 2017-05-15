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

    describe '#private_key' do
      it 'returns a OpenSSL::PKey::RSA' do
        expect(subject.private_key).to be_a(key_class)
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

    describe '#private_key' do
      it 'returns a OpenSSL::PKey::RSA' do
        expect(subject.private_key).to be_a(key_class)
      end
    end
  end

  def generate_key(klass)
    while k = generate_private_key
      return k if k.is_a?(klass)
    end
  end
end
