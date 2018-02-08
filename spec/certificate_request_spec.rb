require 'spec_helper'

describe Acme::Client::CertificateRequest do
  let(:test_key) { generate_private_key }

  it 'reads the common name from the subject' do
    request = Acme::Client::CertificateRequest.new(private_key: test_key, subject: { common_name: 'example.org' })

    expect(request.common_name).to eq('example.org')

    request = Acme::Client::CertificateRequest.new(private_key: test_key, subject: { 'CN' => 'example.org' })

    expect(request.common_name).to eq('example.org')
  end

  it "doesn't modify the given subject" do
    subject = { common_name: 'example.org' }
    original = subject.dup
    Acme::Client::CertificateRequest.new(private_key: test_key, subject: subject)

    expect(subject).to eq(original)
  end

  it 'normalizes the subject to OpenSSL short names' do
    subject = Acme::Client::CertificateRequest::SUBJECT_KEYS.each_with_object({}) {|(key, _), hash|
      hash[key] = 'example'
    }
    request = Acme::Client::CertificateRequest.new(private_key: test_key, subject: subject)

    subject = Acme::Client::CertificateRequest::SUBJECT_KEYS.each_with_object({}) {|(_, short_name), hash|
      hash[short_name] = 'example'
    }
    expect(request.subject).to eq(subject)
  end

  it 'sets the subject common name from the parameter' do
    request = Acme::Client::CertificateRequest.new(common_name: 'example.org', private_key: test_key)

    expect(request.subject['CN']).to eq('example.org')
  end

  it 'adds the common name to the names' do
    request = Acme::Client::CertificateRequest.new(common_name: 'example.org', private_key: test_key)

    expect(request.names).to eq(%w(example.org))
  end

  it 'picks a single domain as the common name' do
    request = Acme::Client::CertificateRequest.new(names: %w(example.org), private_key: test_key)

    expect(request.common_name).to eq('example.org')
    expect(request.subject['CN']).to eq('example.org')
    expect(request.names).to eq(%w(example.org))
  end

  it 'picks the common name from the names' do
    request = Acme::Client::CertificateRequest.new(names: %w(example.org www.example.org), private_key: test_key)

    expect(request.common_name).to eq('example.org')
    expect(request.subject['CN']).to eq('example.org')
    expect(request.names).to eq(%w(example.org www.example.org))
  end

  it 'expects a domain' do
    expect {
      Acme::Client::CertificateRequest.new(private_key: test_key)
    }.to raise_error(ArgumentError, /No common name/)
  end

  it 'disallows arbitrary subject keys' do
    expect {
      Acme::Client::CertificateRequest.new(
        common_name: 'example.org',
        private_key: test_key,
        subject: { :milk => 'yes', 'serialNumber' => 123 }
      )
    }.to raise_error(ArgumentError, /Unexpected subject attributes/)
  end

  it 'checks consistency of given common names' do
    expect {
      Acme::Client::CertificateRequest.new(
        common_name: 'example.org',
        private_key: test_key,
        subject: { common_name: 'example.net' }
      )
    }.to raise_error(ArgumentError, /Conflicting common name/)

    expect {
      Acme::Client::CertificateRequest.new(
        common_name: 'example.org',
        private_key: test_key,
        subject: { 'CN' => 'example.net' }
      )
    }.to raise_error(ArgumentError, /Conflicting common name/)
  end

  it 'assigns the public key' do
    request = Acme::Client::CertificateRequest.new(common_name: 'example.org', private_key: test_key)

    expect(request.csr.public_key.to_der).to eq(public_key_to_der(test_key))
    expect(request.csr.verify(request.csr.public_key)).to be(true)
  end

  it 'adds the common name to the subject' do
    request = Acme::Client::CertificateRequest.new(common_name: 'example.org', private_key: test_key)

    subject = request.csr.subject.to_a.map { |name, value, _| [name, value] }.to_h
    expect(subject['CN']).to eq('example.org')
  end

  it 'adds other valid attributes to the subject' do
    subject_keys = Acme::Client::CertificateRequest::SUBJECT_KEYS
    subject = subject_keys.each_with_object({}) {|(_, short_name), hash|
      hash[short_name] = 'example'
    }
    request = Acme::Client::CertificateRequest.new(private_key: test_key, subject: subject)

    csr_subject = request.csr.subject.to_a.map { |name, value, _| [name, value] }.to_h
    expect(csr_subject).to eq(subject)
  end

  it 'creates a subjectAltName extension with multiple names' do
    request = Acme::Client::CertificateRequest.new(names: %w(example.org www.example.org), private_key: test_key)

    extension = request.csr.attributes.find { |attribute|
      asn1_dig(attribute).first.value == 'subjectAltName'
    }
    expect(extension).not_to be_nil
    value = asn1_dig(extension).last.value
    expect(value).to include('example.org')
    expect(value).to include('www.example.org')
  end

  it 'signs the request with the private key' do
    request = Acme::Client::CertificateRequest.new(common_name: 'example.org', private_key: test_key)

    expect(verify_csr(request.csr, test_key)).to be(true)
  end

  it 'supports ECDSA keys' do
    ec_key = OpenSSL::PKey::EC.new('secp384r1')
    ec_key.generate_key
    request = Acme::Client::CertificateRequest.new(common_name: 'example.org',
                                                   private_key: ec_key)

    expect(request.csr.verify(ec_key)).to be(true)
  end
end
