require 'spec_helper'

describe Acme::Client::Resources::Challenges::DNS01 do
  let(:dns01) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@example.com')
    registration.agree_terms
    authorization = client.authorize(domain: 'test.example.com')
    authorization.dns01
  end

  it 'returns the correct record metadata', vcr: { cassette_name: 'dns01_metadata' } do
    expect(dns01.record_name).to eq '_acme-challenge'
    expect(dns01.record_type).to eq 'TXT'
    expect(dns01.record_content).to be_a(String)
    expect(dns01.to_h['token']).to eq(dns01.token)
    expect(dns01.to_h['uri']).to eq(dns01.uri)
    expect(dns01.to_h['type']).to eq(dns01.class::CHALLENGE_TYPE)
  end

  it 'successfully verify the challenge', vcr: { cassette_name: 'dns01_verify_success' } do
    expect {
      expect(dns01.request_verification).to be(true)
    }.to_not raise_error

    expect {
      retry_until(condition: lambda { dns01.status != 'pending' }) do
        dns01.verify_status
      end
    }.to_not raise_error

    expect(dns01.status).to eq('valid')
  end

  it 'fail to verify the challenge and return the status', vcr: { cassette_name: 'dns01_verify_failure' } do
    expect {
      expect(dns01.request_verification).to be(true)
    }.to_not raise_error

    expect {
      retry_until(condition: lambda { dns01.status != 'pending' }) do
        dns01.verify_status
      end
    }.to_not raise_error

    expect(dns01.status).to eq('invalid')
    expect(dns01.error).to_not be_empty
  end
end
