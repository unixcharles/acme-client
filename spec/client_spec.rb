require 'spec_helper'

describe Acme::Client do
  let(:unregistered_client) { Acme::Client.new(private_key: generate_private_key) }

  let(:registered_client) do
    client = Acme::Client.new(private_key: generate_private_key)
    client.register(contact: 'mailto:mail@test.com')
    client
  end

  let(:active_client) do
    client = Acme::Client.new(private_key: generate_private_key)
    registration = client.register(contact: 'mailto:mail@test.com')
    registration.agree_terms
    client
  end

  context '#register' do
    it 'register successfully', vcr: { cassette_name: 'register_success' } do
      expect {
        registration = unregistered_client.register(contact: %w(mailto:cert-admin@example.com tel:+15145552222))
        expect(registration).to be_a(Acme::Resources::Registration)
      }.to_not raise_error
    end

    it 'fail to register with an invalid contact', vcr: { cassette_name: 'register_invalid_contact' } do
      expect {
        unregistered_client.register(contact: %w(mailto:not-valid))
      }.to raise_error(Acme::Error, /not a valid e-mail address/)
    end

    it 'fail to register a key that is already registered', vcr: { cassette_name: 'register_duplicate_failure' } do
      expect {
        registered_client.register(contact: %w(mailto:cert-admin@example.com tel:+15145552222))
      }.to raise_error(Acme::Error, /Registration key is already in use/)
    end
  end

  context '#authorize' do
    it 'succeed', vcr: { cassette_name: 'authorize_success' } do
      expect {
        registration = active_client.authorize(domain: 'domain.com')
        expect(registration).to be_a(Acme::Resources::Authorization)
      }.to_not raise_error
    end

    it 'fail when the client has not yet agree to the tos', vcr: { cassette_name: 'authorize_fail_tos' } do
      expect {
        registered_client.authorize(domain: 'domain.com')
      }.to raise_error(Acme::Error, /Must agree to subscriber agreement before any further actions/)
    end

    it 'fail when the domain is not valid', vcr: { cassette_name: 'authorize_invalid_domain' } do
      expect {
        active_client.authorize(domain: 'notadomain')
      }.to raise_error(Acme::Error, /Error creating new authz/)
    end
  end

  context '#new_certificate' do
    let(:domain) { "test#{rand(10*10)}.testdomain.com" }
    let(:private_key) { generate_private_key }
    let(:client) { Acme::Client.new(private_key: private_key) }
    let(:csr) { generate_csr(domain, generate_private_key) }

    before(:each) do
      registration = client.register(contact: 'mailto:info@test.com')
      registration.agree_terms
      authorization = client.authorize(domain: domain)
      http01 = authorization.http01

      serve_once(http01.file_content) do
        http01.request_verification
        retry_until(condition: lambda { http01.status != 'pending' }) do
          http01.verify_status
        end
      end
    end

    it 'retrieve a new certificate successfully', vcr: { cassette_name: 'new_certificate_success' } do
      certificate = nil

      expect {
        certificate = client.new_certificate(csr)
      }.to_not raise_error

      expect(certificate).to be_a(OpenSSL::X509::Certificate)
    end
  end
end
