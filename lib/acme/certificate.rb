class Acme::Certificate
  extend Forwardable

  attr_reader :x509, :x509_chain, :request, :private_key

  def_delegators :x509, :to_pem, :to_der

  def initialize(certificate, chain, request)
    @x509 = certificate
    @x509_chain = chain
    @request = request

    #create_self_signed_cert if x509.nil?
  end

  def create_self_signed_cert subjectAltDomains
    keypair = OpenSSL::PKey::RSA.new(2048) 

    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse "/CN=#{dummy}"
    cert.not_before = Time.now - 2*24*3600
    cert.not_after = Time.now + 14*24*3600
    cert.public_key = keypair.public_key
    cert.version = 2 # X509v3
    cert.serial = 0x0

    ext = []

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert

    cert.add_extension ef.create_extension("basicConstraints","CA:TRUE", true),
    cert.add_extentions ef.create_extension("subjectKeyIdentifier", "hash"),
    cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")
    cert.add_extension ef.create_extension("subjectAltName", subjectAltDomains.map { |d| "DNS: #{d}" }.join(','))

    cert.sign(keypair, OpenSSL::Digest::SHA256.new)
    @private_key = keypair
    @x509 = cert
    true
  end

  def chain_to_pem
    x509_chain.map(&:to_pem).join
  end

  def x509_fullchain
    [x509, *x509_chain]
  end

  def fullchain_to_pem
    x509_fullchain.map(&:to_pem).join
  end

  def common_name
    x509.subject.to_a.find {|name, _, _| name == "CN" }[1]
  end
end
