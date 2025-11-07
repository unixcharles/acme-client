require 'spec_helper'

describe 'Acme::Client renewal_info' do
  let(:private_key) { generate_private_key }
  let(:client) do
    client = Acme::Client.new(private_key: private_key, directory: DIRECTORY_URL)
    client.new_account(contact: "mailto:info@#{EXAMPLE_DOMAIN}", terms_of_service_agreed: true)
    client
  end

  context 'when ARI is supported', vcr: { cassette_name: 'renewal_info_supported' } do
    let(:certificate_pem) { File.read('spec/fixtures/certificate_chain.pem') }

    it 'returns renewal information for a certificate' do
      renewal_info = client.renewal_info(certificate: certificate_pem)

      expect(renewal_info).to be_a(Acme::Client::Resources::RenewalInfo)
      expect(renewal_info.suggested_window).to be_a(Hash)
      expect(renewal_info.suggested_window_start).to be_a(String)
      expect(renewal_info.suggested_window_end).to be_a(String)
    end

    it 'parses suggested window dates' do
      renewal_info = client.renewal_info(certificate: certificate_pem)

      # Dates should be in RFC 3339 format
      expect { Time.parse(renewal_info.suggested_window_start) }.not_to raise_error
      expect { Time.parse(renewal_info.suggested_window_end) }.not_to raise_error
    end

    it 'returns explanation_url if provided' do
      renewal_info = client.renewal_info(certificate: certificate_pem)

      # explanation_url is optional per RFC 9773
      if renewal_info.explanation_url
        expect(renewal_info.explanation_url).to be_a(String)
      end
    end

    it 'returns retry_after if provided' do
      renewal_info = client.renewal_info(certificate: certificate_pem)

      # retry_after is optional per RFC 9773
      if renewal_info.retry_after
        expect(renewal_info.retry_after).to be_a(String)
      end
    end

    it 'converts to hash' do
      renewal_info = client.renewal_info(certificate: certificate_pem)
      hash = renewal_info.to_h

      expect(hash).to be_a(Hash)
      expect(hash).to have_key(:suggested_window)
      expect(hash).to have_key(:explanation_url)
      expect(hash).to have_key(:retry_after)
    end

    it 'selects a random renewal time within the suggested window' do
      renewal_info = client.renewal_info(certificate: certificate_pem)

      start_time = Time.parse(renewal_info.suggested_window_start)
      end_time = Time.parse(renewal_info.suggested_window_end)

      selected_time = renewal_info.suggested_renewal_time

      expect(selected_time).to be_a(Time)

      if selected_time > Time.now
        expect(selected_time).to be >= start_time
        expect(selected_time).to be <= end_time
      else
        expect(selected_time).to be_within(1).of(Time.now)
      end
    end

    it 'returns Time.now if selected time is in the past' do
      renewal_info = client.renewal_info(certificate: certificate_pem)

      allow(renewal_info).to receive(:suggested_window_start).and_return((Time.now - 7200).iso8601)
      allow(renewal_info).to receive(:suggested_window_end).and_return((Time.now - 3600).iso8601)

      selected_time = renewal_info.suggested_renewal_time

      expect(selected_time).to be_within(1).of(Time.now)
    end
  end

  context 'replaces field in new order' do
    let(:certificate_pem) { File.read('spec/fixtures/certificate_chain.pem') }

    it 'accepts replaces parameter with ARI certificate identifier', vcr: { cassette_name: 'new_order_with_replaces' } do
      cert_id = Acme::Client::Util.ari_certificate_identifier(certificate_pem)

      order = client.new_order(identifiers: [EXAMPLE_DOMAIN], replaces: cert_id)

      expect(order).to be_a(Acme::Client::Resources::Order)
      expect(order.status).to eq('pending')
    end
  end

  context 'certificate identifier generation' do
    let(:certificate_pem) { File.read('spec/fixtures/certificate_chain.pem') }
    let(:cert) { OpenSSL::X509::Certificate.new(certificate_pem) }

    it 'generates a valid certificate identifier' do
      cert_id = Acme::Client::Util.ari_certificate_identifier(cert)

      # Should be in format: base64url(AKI).base64url(serial)
      expect(cert_id).to match(/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/)
      expect(cert_id).not_to include('=') # No padding
    end

    it 'accepts PEM string as input' do
      cert_id = Acme::Client::Util.ari_certificate_identifier(certificate_pem)
      expect(cert_id).to be_a(String)
    end

    it 'accepts OpenSSL::X509::Certificate as input' do
      cert_id = Acme::Client::Util.ari_certificate_identifier(cert)
      expect(cert_id).to be_a(String)
    end

    it 'generates consistent identifiers for the same certificate' do
      cert_id1 = Acme::Client::Util.ari_certificate_identifier(cert)
      cert_id2 = Acme::Client::Util.ari_certificate_identifier(certificate_pem)

      expect(cert_id1).to eq(cert_id2)
    end

    it 'raises error if certificate has no AKI extension' do
      # Create a self-signed certificate without AKI extension
      key = OpenSSL::PKey::RSA.new(2048)
      cert_without_aki = OpenSSL::X509::Certificate.new
      cert_without_aki.version = 2
      cert_without_aki.serial = 1
      cert_without_aki.subject = OpenSSL::X509::Name.parse('/CN=Test')
      cert_without_aki.issuer = cert_without_aki.subject
      cert_without_aki.public_key = key.public_key
      cert_without_aki.not_before = Time.now
      cert_without_aki.not_after = Time.now + 365 * 24 * 60 * 60
      cert_without_aki.sign(key, OpenSSL::Digest::SHA256.new)

      expect {
        Acme::Client::Util.ari_certificate_identifier(cert_without_aki)
      }.to raise_error(ArgumentError, /does not have an Authority Key Identifier/)
    end
  end
end
