class Acme::Client::JWK::ECDSA < Acme::Client::JWK::Base
  # ECDSA Curves supported by JWA.
  # https://tools.ietf.org/html/rfc7518#section-3.1
  KNOWN_CURVES = %w(
    prime256v1
    secp384r1
    secp521r1
  ).freeze

  # Mapping from OpenSSL curve names to associated digests.
  # https://tools.ietf.org/html/rfc7518#section-3.1
  DIGEST_MAP = {
    'prime256v1' => OpenSSL::Digest::SHA256,
    'secp384r1'  => OpenSSL::Digest::SHA384,
    'secp521r1'  => OpenSSL::Digest::SHA512
  }.freeze

  # Mappings from OpenSSL to JWA "crv" names.
  # https://tools.ietf.org/html/rfc7518#section-3.1
  JWA_CRV_MAP = {
    'prime256v1' => 'P-256',
    'secp384r1'  => 'P-384',
    'secp521r1'  => 'P-521'
  }.freeze

  # Mapping from OpenSSL curve names to associated JWS "alg" names.
  # https://tools.ietf.org/html/rfc7518#section-3.1
  JWA_ALG_MAP = {
    'prime256v1' => 'ES256',
    'secp384r1'  => 'ES384',
    'secp521r1'  => 'ES512'
  }.freeze

  attr_reader :private_key, :jwa_alg

  # Instantiate a new ECDSA JWK.
  #
  # private_key - A OpenSSL::PKey::EC instance.
  #
  # Returns nothing.
  def initialize(private_key)
    unless private_key.is_a?(OpenSSL::PKey::EC)
      raise ArgumentError, 'private_key must be a OpenSSL::PKey::EC'
    end

    curve = private_key.group.curve_name
    raise ArgumentError, 'Unknown EC curve' unless KNOWN_CURVES.include?(curve)

    @private_key = private_key
    @digest = DIGEST_MAP[curve]
    @jwa_crv = JWA_CRV_MAP[curve]
    @jwa_alg = JWA_ALG_MAP[curve]
  end

  # Get this JWK as a Hash for JSON serialization.
  #
  # Returns a Hash.
  def to_h
    {
      crv: @jwa_crv,
      kty: 'EC',
      x: Acme::Client::Crypto.urlsafe_base64(coordinates[:x].to_s(2)),
      y: Acme::Client::Crypto.urlsafe_base64(coordinates[:y].to_s(2))
    }
  end

  # Sign a message with the private key.
  #
  # message - A String message to sign.
  #
  # Returns a String signature.
  def sign(message)
    private_key.sign(@digest.new, message)
  end

  private

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
    private_key.public_key
  end
end
