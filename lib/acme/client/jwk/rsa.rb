class Acme::Client::JWK::RSA < Acme::Client::JWK::Base
  # Digest algorithm to use when signing.
  DIGEST = OpenSSL::Digest::SHA256

  # Instantiate a new RSA JWK.
  #
  # private_key - A 256 bit OpenSSL::PKey::RSA instance.
  #
  # Returns nothing.
  def initialize(private_key)
    unless private_key.is_a?(OpenSSL::PKey::RSA)
      raise ArgumentError, 'private_key must be a OpenSSL::PKey::RSA'
    end

    @private_key = private_key
  end

  # Get this JWK as a Hash for JSON serialization.
  #
  # Returns a Hash.
  def to_h
    {
      e: Acme::Client::Util.urlsafe_base64(public_key.e.to_s(2)),
      kty: 'RSA',
      n: Acme::Client::Util.urlsafe_base64(public_key.n.to_s(2))
    }
  end

  # Sign a message with the private key.
  #
  # message - A String message to sign.
  #
  # Returns a String signature.
  def sign(message)
    @private_key.sign(DIGEST.new, message)
  end

  # The name of the algorithm as needed for the `alg` member of a JWS object.
  #
  # Returns a String.
  def jwa_alg
    # https://tools.ietf.org/html/rfc7518#section-3.1
    # RSASSA-PKCS1-v1_5 using SHA-256
    'RS256'
  end

  private

  def public_key
    @private_key.public_key
  end
end
