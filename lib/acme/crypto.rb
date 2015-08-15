class Acme::Crypto
  attr_reader :private_key

  def initialize(private_key)
    @private_key = private_key
  end

  def generate_signed_jws(header:, payload:)
    protection_header = generate_protection_header(header)
    payload = encode64(JSON.dump(payload))

    JSON.dump(
      {
        header: { alg: :RS256, jwk: jwk },
        protected: protection_header,
        payload: payload,
        signature: generate_signature(protection_header, payload)
      }
    )
  end

  def generate_signature(protection_header, payload)
    input = "#{protection_header}.#{payload}"
    signature = private_key.sign(digest, input)
    encode64(signature)
  end

  def generate_protection_header(header)
    encode64(JSON.dump(header))
  end

  def jwk
    JSON::JWK.new(public_key).to_hash
  end

  def public_key
    private_key.public_key
  end

  def digest
    OpenSSL::Digest::SHA256.new
  end

  def encode64(input)
    UrlSafeBase64.encode64(input)
  end
end
