class Acme::Client::Crypto
  THUMBPRINT_DIGEST = OpenSSL::Digest::SHA256

  attr_accessor :jwk

  def self.from_jwk(jwk)
    new(nil, jwk: jwk)
  end

  def initialize(private_key, jwk: nil)
    if jwk.nil?
      case private_key
      when OpenSSL::PKey::RSA
        @jwk = Acme::Client::JWK::RSA.new(private_key)
      when OpenSSL::PKey::EC
        @jwk = Acme::Client::JWK::ECDSA.new(private_key)
      else
        raise ArgumentError, "Can't handle #{private_key} as private key, only OpenSSL::PKey::RSA and OpenSSL::PKey::EC"
      end
    else
      @jwk = jwk
    end
  end

  def generate_signed_jws(header:, payload:)
    header = base_jws_header.merge(header)
    encoded_header = Acme::Client::Util.urlsafe_base64(header.to_json)
    encoded_payload = Acme::Client::Util.urlsafe_base64(payload.to_json)
    signature_data = "#{encoded_header}.#{encoded_payload}"

    signature = jwk.sign signature_data
    encoded_signature = Acme::Client::Util.urlsafe_base64(signature)

    {
      protected: encoded_header,
      payload: encoded_payload,
      signature: encoded_signature
    }.to_json
  end

  def base_jws_header
    {
      typ: 'JWT',
      alg: jwk.jwa_alg,
      jwk: jwk.to_h
    }
  end

  def thumbprint
    Acme::Client::Util.urlsafe_base64 THUMBPRINT_DIGEST.digest(jwk.to_json)
  end

  def private_key
    jwk.private_key
  end
end
