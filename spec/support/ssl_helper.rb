require 'yaml'

module SSLHelper
  class KeyStash
    KEYSTASH_PATH = File.join(__dir__, '../fixtures/keystash.yml')

    def initialize
      @keystash = load
      @iter = @keystash.each
    end

    def next
      @iter.next
    rescue StopIteration
      @keystash << OpenSSL::PKey::RSA.new(2048)
      save
      @keystash.last
    end

    private

    def load
      if File.exist?(KEYSTASH_PATH)
        YAML.load_file(KEYSTASH_PATH).map { |key| OpenSSL::PKey::RSA.new(key) }
      else
        []
      end
    end

    def save
      File.write(KEYSTASH_PATH, YAML.dump(@keystash.map(&:to_pem)))
    end
  end

  KEYSTASH = KeyStash.new

  def generate_private_key
    KEYSTASH.next
  end

  def generate_ecdsa_private_key
    ec_key = OpenSSL::PKey::EC.new('prime256v1')
    ec_key.generate_key
    ec_key
  end

  def generate_csr(common_name, private_key)
    request = OpenSSL::X509::Request.new
    request.subject = OpenSSL::X509::Name.new(
      [
        [
          'CN',
          common_name,
          OpenSSL::ASN1::UTF8STRING
        ]
      ]
    )

    request.public_key = private_key.public_key
    request.sign(private_key, OpenSSL::Digest::SHA256.new)
    request
  end
end
