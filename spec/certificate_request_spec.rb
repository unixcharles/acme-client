require 'spec_helper'

describe Acme::CertificateRequest do
  before(:all) do
    @test_key = generate_private_key
  end

  it "checks for a valid digest" do
    expect {
      Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key, digest: :not_a_digest)
    }.to raise_error(ArgumentError, /OpenSSL::Digest/)
  end

  it "reads the common name from the subject" do
    request = Acme::CertificateRequest.new(private_key: @test_key, subject: {common_name: "example.org"})

    expect(request.common_name).to eq("example.org")

    request = Acme::CertificateRequest.new(private_key: @test_key, subject: {"CN" => "example.org"})

    expect(request.common_name).to eq("example.org")
  end

  it "doesn't modify the given subject" do
    subject = {common_name: "example.org"}
    original = subject.dup
    Acme::CertificateRequest.new(private_key: @test_key, subject: subject)

    expect(subject).to eq(original)
  end

  it "normalizes the subject to OpenSSL short names" do
    subject = Acme::CertificateRequest::SUBJECT_KEYS.each_with_object({}) {|(key, _), subject|
      subject[key] = "example"
    }
    request = Acme::CertificateRequest.new(private_key: @test_key, subject: subject)

    subject = Acme::CertificateRequest::SUBJECT_KEYS.each_with_object({}) {|(_, short_name), subject|
      subject[short_name] = "example"
    }
    expect(request.subject).to eq(subject)
  end

  it "sets the subject common name from the parameter" do
    request = Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key)

    expect(request.subject["CN"]).to eq("example.org")
  end

  it "doesn't modify the given names" do
    names = %w[www.example.org example.net]
    original = names.dup
    request = Acme::CertificateRequest.new(common_name: "example.org", names: names, private_key: @test_key)

    expect(names).to eq(original)
  end

  it "adds the common name to the names" do
    request = Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key)

    expect(request.names).to eq(%w[example.org])
  end

  it "picks a single domain as the common name" do
    request = Acme::CertificateRequest.new(names: %w[example.org], private_key: @test_key)

    expect(request.common_name).to eq("example.org")
    expect(request.subject["CN"]).to eq("example.org")
    expect(request.names).to eq(%w[example.org])
  end

  it "picks the common name from the names" do
    request = Acme::CertificateRequest.new(names: %w[example.org www.example.org], private_key: @test_key)

    expect(request.common_name).to eq("example.org")
    expect(request.subject["CN"]).to eq("example.org")
    expect(request.names).to eq(%w[example.org www.example.org])
  end

  it "expects a domain" do
    expect {
      Acme::CertificateRequest.new(private_key: @test_key)
    }.to raise_error(ArgumentError, /No common name/)
  end

  it "disallows arbitrary subject keys" do
    expect {
      Acme::CertificateRequest.new(
        common_name: "example.org",
        private_key: @test_key,
        subject: {:milk => "yes", "serialNumber" => 123}
      )
    }.to raise_error(ArgumentError, /Unexpected subject attributes/)
  end

  it "checks consistency of given common names" do
    expect {
      Acme::CertificateRequest.new(
        common_name: "example.org",
        private_key: @test_key,
        subject: {common_name: "example.net"}
      )
    }.to raise_error(ArgumentError, /Conflicting common name/)

    expect {
      Acme::CertificateRequest.new(
        common_name: "example.org",
        private_key: @test_key,
        subject: {"CN" => "example.net"}
      )
    }.to raise_error(ArgumentError, /Conflicting common name/)
  end

  it "assigns the public key" do
    request = Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key)

    expect(request.csr.public_key.to_der).to eq(@test_key.public_key.to_der)
    expect(request.csr.verify(request.csr.public_key)).to be(true)
  end

  it "adds the common name to the subject" do
    request = Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key)

    subject = request.csr.subject.to_a.map {|name, value, _| [name, value] }.to_h
    expect(subject["CN"]).to eq("example.org")
  end

  it "adds other valid attributes to the subject" do
    subject = Acme::CertificateRequest::SUBJECT_KEYS.each_with_object({}) {|(_, short_name), subject|
      subject[short_name] = "example"
    }
    request = Acme::CertificateRequest.new(private_key: @test_key, subject: subject)

    csr_subject = request.csr.subject.to_a.map {|name, value, _| [name, value] }.to_h
    expect(csr_subject).to eq(subject)
  end

  it "does not create a subjectAltName extension with a single domain" do
    request = Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key)

    expect(request.csr.attributes).to be_empty
  end

  it "creates a subjectAltName extension with multiple names" do
    request = Acme::CertificateRequest.new(names: %w[example.org www.example.org], private_key: @test_key)

    extension = request.csr.attributes.find {|attribute|
      attribute.value.first.first.value.first.value == "subjectAltName"
    }
    expect(extension).not_to be_nil
    value = extension.value.first.first.value.last.value
    expect(value).to include("example.org")
    expect(value).to include("www.example.org")
  end

  it "signs the request with the private key" do
    request = Acme::CertificateRequest.new(common_name: "example.org", private_key: @test_key)

    expect(request.csr.verify(@test_key.public_key)).to be(true)
  end
end
