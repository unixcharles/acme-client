require 'spec_helper'

describe Acme::Client::SelfSignCertificate do
  it 'generate a self sign certificate' do
    self_sign_certificate = Acme::Client::SelfSignCertificate.new(subject_alt_names: ['test.example.org'])
    expect(self_sign_certificate.certificate).to be_a(OpenSSL::X509::Certificate)
    expect(self_sign_certificate.private_key).to be_a(OpenSSL::PKey::RSA)
  end

  it 'generate a self sign certificate from a provided private key' do
    private_key = generate_private_key
    self_sign_certificate = Acme::Client::SelfSignCertificate.new(private_key: private_key, subject_alt_names: ['test.example.org'])
    expect(self_sign_certificate.certificate).to be_a(OpenSSL::X509::Certificate)
    expect(self_sign_certificate.private_key).to be(private_key)
  end

  it 'sets the certificates version' do
    private_key = generate_private_key
    self_sign_certificate = Acme::Client::SelfSignCertificate.new(private_key: private_key, subject_alt_names: ['test.example.org'])
    expect(self_sign_certificate.certificate.version).to eql(2)
  end
end
