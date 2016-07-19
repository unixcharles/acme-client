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
      decoded_jwt = JSON::JWT.decode(JSON.load(signed_jws), private_key.public_key)
      expect(decoded_jwt).to include('some' => 'data')
      expect(decoded_jwt.header).to include('a-header' => 'header-value')
    end
  end
end
