class Acme::Client::JWK::ECDSA < Acme::Client::JWK::Base
  # JWA parameters for supported OpenSSL curves.
  # https://tools.ietf.org/html/rfc7518#section-3.1
  KNOWN_CURVES = {
    'prime256v1' => {
      jwa_crv: 'P-256',
      jwa_alg: 'ES256',
      digest: OpenSSL::Digest::SHA256
    }.freeze,
    'secp384r1' => {
      jwa_crv: 'P-384',
      jwa_alg: 'ES384',
      digest: OpenSSL::Digest::SHA384
    }.freeze,
    'secp521r1' => {
      jwa_crv: 'P-521',
      jwa_alg: 'ES512',
      digest: OpenSSL::Digest::SHA512
    }.freeze
  }.freeze

  # Instantiate a new ECDSA JWK.
  #
  # private_key - A OpenSSL::PKey::EC instance.
  #
  # Returns nothing.
  def initialize(private_key)
    unless private_key.is_a?(OpenSSL::PKey::EC)
      raise ArgumentError, 'private_key must be a OpenSSL::PKey::EC'
    end

    unless @curve_params = KNOWN_CURVES[private_key.group.curve_name]
      raise ArgumentError, 'Unknown EC curve'
    end

    @private_key = private_key
  end

  # The name of the algorithm as needed for the `alg` member of a JWS object.
  #
  # Returns a String.
  def jwa_alg
    @curve_params[:jwa_alg]
  end

  # Get this JWK as a Hash for JSON serialization.
  #
  # Returns a Hash.
  def to_h
    {
      crv: @curve_params[:jwa_crv],
      kty: 'EC',
      x: Acme::Client::Util.urlsafe_base64(coordinates[:x].to_s(2)),
      y: Acme::Client::Util.urlsafe_base64(coordinates[:y].to_s(2))
    }
  end

  # Sign a message with the private key.
  #
  # message - A String message to sign.
  #
  # Returns a String signature.
  def sign(message)
    # DER encoded ASN.1 signature
    der = @private_key.sign(@curve_params[:digest].new, message)

    # ASN.1 SEQUENCE
    seq = OpenSSL::ASN1.decode(der)

    # ASN.1 INTs
    ints = seq.value

    # BigNumbers
    bns = ints.map(&:value)

    # Binary R/S values
    r, s = bns.map { |bn| [bn.to_s(16)].pack('H*') }

    # JWS wants raw R/S concatenated.
    [r, s].join
  end

  private

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

  def public_key
    @private_key.public_key
  end
end
