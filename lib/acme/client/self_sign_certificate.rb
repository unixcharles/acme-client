class Acme::Client::SelfSignCertificate
  attr_reader :private_key, :subject_alt_names, :not_before, :not_after

  extend Forwardable
  def_delegators :certificate, :to_pem, :to_der

  def initialize(subject_alt_names:, not_before: default_not_before, not_after: default_not_after, private_key: generate_private_key)
    @private_key = private_key
    @subject_alt_names = subject_alt_names
    @not_before = not_before
    @not_after = not_after
  end

  def certificate
    @certificate ||= begin
      certificate = generate_certificate

      extension_factory = generate_extension_factory(certificate)
      subject_alt_name_entry = subject_alt_names.map { |d| "DNS: #{d}" }.join(',')
      subject_alt_name_extension = extension_factory.create_extension('subjectAltName', subject_alt_name_entry)
      certificate.add_extension(subject_alt_name_extension)

      certificate.sign(private_key, digest)
    end
  end

  private

  def generate_private_key
    OpenSSL::PKey::RSA.new(2048)
  end

  def default_not_before
    Time.now - 3600
  end

  def default_not_after
    Time.now + 30 * 24 * 3600
  end

  def digest
    OpenSSL::Digest::SHA256.new
  end

  def generate_certificate
    certificate = OpenSSL::X509::Certificate.new
    certificate.not_before = not_before
    certificate.not_after = not_after
    certificate.public_key = private_key.public_key
    certificate.version = 2
    certificate.serial = 1
    certificate
  end

  def generate_extension_factory(certificate)
    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = certificate
    extension_factory.issuer_certificate = certificate
    extension_factory
  end
end
