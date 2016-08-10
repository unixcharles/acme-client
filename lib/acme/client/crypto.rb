class Acme::Client::Crypto
  attr_reader :private_key

  def initialize(private_key)
    @private_key = private_key
  end

  def generate_signed_jws(header:, payload:)
    header = { typ: 'JWT', alg: jws_alg, jwk: jwk }.merge(header)

    encoded_header = urlsafe_base64(header.to_json)
    encoded_payload = urlsafe_base64(payload.to_json)
    signature_data = "#{encoded_header}.#{encoded_payload}"

    signature = private_key.sign digest, signature_data
    encoded_signature = urlsafe_base64(signature)

    {
      protected: encoded_header,
      payload: encoded_payload,
      signature: encoded_signature
    }.to_json
  end

  def thumbprint
    urlsafe_base64 digest.digest(jwk.to_json)
  end

  def digest
    OpenSSL::Digest::SHA256.new
  end

  def urlsafe_base64(data)
    Base64.urlsafe_encode64(data).sub(/[\s=]*\z/, '')
  end

  private

  def jws_alg
    { 'RSA' => 'RS256', 'EC' => 'ES256' }.fetch(jwk[:kty])
  end

  def jwk
    @jwk ||= case private_key
             when OpenSSL::PKey::RSA
               rsa_jwk
             when OpenSSL::PKey::EC
               ec_jwk
             else
               raise ArgumentError, "Can't handle #{private_key} as private key, only OpenSSL::PKey::RSA and OpenSSL::PKey::EC"
    end
  end

  def rsa_jwk
    {
      e: urlsafe_base64(public_key.e.to_s(2)),
      kty: 'RSA',
      n: urlsafe_base64(public_key.n.to_s(2))
    }
  end

  def ec_jwk
    {
      crv: curve_name,
      kty: 'EC',
      x: urlsafe_base64(coordinates[:x].to_s(2)),
      y: urlsafe_base64(coordinates[:y].to_s(2))
    }
  end

  def curve_name
    {
      'prime256v1' => 'P-256',
      'secp384r1' => 'P-384',
      'secp521r1' => 'P-521'
    }.fetch(private_key.group.curve_name) { raise ArgumentError, 'Unknown EC curve' }
  end

  # rubocop:disable Metrics/AbcSize
  def coordinates
    @coordinates ||= begin
      hex = public_key.to_bn.to_s(16)
      data_len = hex.length - 2
      hex_x = hex[2, data_len / 2]
      hex_y = hex[2 + data_len / 2, data_len / 2]

      {
        x: OpenSSL::BN.new([hex_x].pack('H*'), 2),
        y: OpenSSL::BN.new([hex_y].pack('H*'), 2)
      }
    end
  end
  # rubocop:enable Metrics/AbcSize

  def public_key
    @public_key ||= private_key.public_key
  end
end
