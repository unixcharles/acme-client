require 'spec_helper'

describe Acme::Client::ChainIdentifier do
  let(:pem) { open('./spec/fixtures/certificate_chain.pem').read }
  let(:issuer_name) { 'Pebble Root CA' }

  subject { Acme::Client::ChainIdentifier.new(pem) }
  it 'matches certificate by name' do
    expect(subject).to be_a_match_name(issuer_name)
  end

  it 'fail non matching certificate name' do
    expect(subject).not_to be_a_match_name('foo')
  end
end
