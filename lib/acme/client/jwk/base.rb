class Acme::Client::JWK::Base
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
    raise 'not implemented'
  end

  # Sign a message with the private key.
  #
  # message - A String message to sign.
  #
  # Returns a String signature.
  # rubocop:disable Lint/UnusedMethodArgument
  def sign(message)
    raise 'not implemented'
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # The name of the algorithm as needed for the `alg` member of a JWS object.
  #
  # Returns a String.
  def jwa_alg
    raise 'not implemented'
  end

  # The JWK's private key.
  #
  # Returns an Object.
  def private_key
    raise 'not implemented'
  end
end
