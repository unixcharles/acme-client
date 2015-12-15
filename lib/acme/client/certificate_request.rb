class Acme::Client::CertificateRequest
  extend Forwardable

  DEFAULT_KEY_LENGTH = 2048
  DEFAULT_DIGEST = OpenSSL::Digest::SHA256
  SUBJECT_KEYS = {
    common_name:         "CN",
    country_name:        "C",
    organization_name:   "O",
    organizational_unit: "OU",
    state_or_province:   "ST",
    locality_name:       "L"
  }.freeze

  SUBJECT_TYPES = {
    "CN" => OpenSSL::ASN1::UTF8STRING,
    "C"  => OpenSSL::ASN1::UTF8STRING,
    "O"  => OpenSSL::ASN1::UTF8STRING,
    "OU" => OpenSSL::ASN1::UTF8STRING,
    "ST" => OpenSSL::ASN1::UTF8STRING,
    "L"  => OpenSSL::ASN1::UTF8STRING
  }.freeze

  attr_reader :private_key, :common_name, :names, :subject

  def_delegators :csr, :to_pem, :to_der

  def initialize(common_name: nil,
                 names: [],
                 private_key: generate_private_key,
                 subject: {},
                 digest: DEFAULT_DIGEST.new)
    raise ArgumentError.new("Digest must be a OpenSSL::Digest") unless digest.is_a?(OpenSSL::Digest)
    @digest = digest

    @private_key = private_key

    @subject = normalize_subject(subject)
    @common_name = common_name || @subject[SUBJECT_KEYS[:common_name]] || @subject[:common_name]

    @names = names.to_a.dup
    normalize_names

    @subject[SUBJECT_KEYS[:common_name]] ||= @common_name
    validate_subject
  end

  def csr
    @csr ||= generate
  end

  private

  def generate_private_key
    OpenSSL::PKey::RSA.new(DEFAULT_KEY_LENGTH)
  end

  def normalize_subject(subject)
    @subject = subject.each_with_object({}) {|(key, value), subject|
      subject[SUBJECT_KEYS.fetch(key, key)] = value.to_s
    }
  end

  def normalize_names
    if @common_name
      @names.unshift(@common_name) unless @names.include?(@common_name)
    elsif @names.empty?
      raise ArgumentError.new("No common name and no list of names given")
    else
      @common_name = @names.first
    end
  end

  def validate_subject
    extra_keys = @subject.keys - SUBJECT_KEYS.keys - SUBJECT_KEYS.values
    unless extra_keys.empty?
      raise ArgumentError.new("Unexpected subject attributes given: #{extra_keys.inspect}")
    end

    unless @common_name == @subject[SUBJECT_KEYS[:common_name]]
      raise ArgumentError.new("Conflicting common name given in arguments and subject")
    end
  end

  def generate
    OpenSSL::X509::Request.new.tap do |csr|
      csr.public_key = @private_key.public_key
      csr.subject = generate_subject
      add_extension(csr)
      csr.sign @private_key, @digest
    end
  end

  def generate_subject
    OpenSSL::X509::Name.new(
      @subject.map {|name, value|
        [name, value, SUBJECT_TYPES[name]]
      }
    )
  end

  def add_extension(csr)
    return if @names.size <= 1

    extension = OpenSSL::X509::ExtensionFactory.new.create_extension(
      "subjectAltName", @names.map {|name| "DNS:#{name}" }.join(", "), false
    )
    csr.add_attribute(
      OpenSSL::X509::Attribute.new(
        "extReq",
        OpenSSL::ASN1::Set.new([OpenSSL::ASN1::Sequence.new([extension])])
      )
    )
  end
end
