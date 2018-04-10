class Acme::Client::JWK::Base
  THUMBPRINT_DIGEST = OpenSSL::Digest::SHA256

  # Initialize a new JWK.
  #
  # Returns nothing.
  def initialize
    raise NotImplementedError
  end

  # Generate a JWS JSON web signature.
  #
  # header  - A Hash of extra header fields to include.
  # payload - A Hash of payload data.
  #
  # Returns a JSON String.
  def jws(header: {}, payload: {})
    header = jws_header(header)
    encoded_header = Acme::Client::Util.urlsafe_base64(header.to_json)
    encoded_payload = Acme::Client::Util.urlsafe_base64(payload.to_json)

    signature_data = "#{encoded_header}.#{encoded_payload}"
    signature = sign(signature_data)
    encoded_signature = Acme::Client::Util.urlsafe_base64(signature)

    {
      protected: encoded_header,
      payload: encoded_payload,
      signature: encoded_signature
    }.to_json
  end

  # Serialize this JWK as JSON.
  #
  # Returns a JSON string.
  def to_json
    to_h.to_json
  end

  # Get this JWK as a Hash for JSON serialization.
  #
  # Returns a Hash.
  def to_h
    raise NotImplementedError
  end

  # JWK thumbprint as used for key authorization.
  #
  # Returns a String.
  def thumbprint
    Acme::Client::Util.urlsafe_base64(THUMBPRINT_DIGEST.digest(to_json))
  end

  # Header fields for a JSON web signature.
  #
  # typ: - Value for the `typ` field. Default 'JWT'.
  #
  # Returns a Hash.
  def jws_header(header)
    jws = {
      typ: 'JWT',
      alg: jwa_alg
    }.merge(header)
    jws[:jwk] = to_h if header[:kid].nil?
    jws
  end

  # The name of the algorithm as needed for the `alg` member of a JWS object.
  #
  # Returns a String.
  def jwa_alg
    raise NotImplementedError
  end

  # Sign a message with the private key.
  #
  # message - A String message to sign.
  #
  # Returns a String signature.
  # rubocop:disable Lint/UnusedMethodArgument
  def sign(message)
    raise NotImplementedError
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
