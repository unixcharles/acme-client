require 'spec_helper'

describe Acme::Client::Resources::Challenges::TLSSNI01 do
  let(:tls_sni01) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:info@example.com')
    registration.agree_terms
    authorization = client.authorize(domain: "test#{rand(10 * 10)}.example.org")
    authorization.tls_sni01
  end

  it 'returns the correct certificate', vcr: { cassette_name: 'tls_sni01_metadata' } do
    expect(tls_sni01.certificate).to be_a(OpenSSL::X509::Certificate)
    expect(tls_sni01.private_key).to be_a(OpenSSL::PKey::RSA)
    expect(tls_sni01.to_h['token']).to eq(tls_sni01.token)
    expect(tls_sni01.to_h['uri']).to eq(tls_sni01.uri)
    expect(tls_sni01.to_h['type']).to eq(tls_sni01.class::CHALLENGE_TYPE)
  end

  context '#verify' do
    it 'successfully verify the challenge', vcr: { cassette_name: 'tls_sni01_verify_success' } do
      listen_tls(tls_sni01.certificate, tls_sni01.private_key) do
        expect {
          expect(tls_sni01.request_verification).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { tls_sni01.status != 'pending' }) do
            tls_sni01.verify_status
          end
        }.to_not raise_error

        expect(tls_sni01.status).to eq('valid')
      end
    end

    it 'fail to verify the challenge and return the status', vcr: { cassette_name: 'tls_sni01_verify_failure' } do
      self_sign = Acme::Client::SelfSignCertificate.new(subject_alt_names: ['fail.example.com'])

      listen_tls(self_sign.certificate, self_sign.private_key) do
        expect {
          expect(tls_sni01.request_verification).to be(true)
        }.to_not raise_error

        expect {
          retry_until(condition: lambda { tls_sni01.status != 'pending' }) do
            tls_sni01.verify_status
          end
        }.to_not raise_error

        expect(tls_sni01.status).to eq('invalid')
        expect(tls_sni01.error).to_not be_empty
      end
    end
  end
end
