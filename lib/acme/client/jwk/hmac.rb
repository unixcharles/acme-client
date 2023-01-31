# frozen_string_literal: true

class Acme::Client::JWK::HMAC < Acme::Client::JWK::Base
  # Instantiate a new HMAC JWS.
  #
  # key - A string.
  #
  # Returns nothing.
  def initialize(key)
    @key = key
  end

  # Sign a message with the private key.
  #
  # message - A String message to sign.
  #
  # Returns a String signature.
  def sign(message)
    OpenSSL::HMAC.digest('SHA256', @key, message)
  end

  # The name of the algorithm as needed for the `alg` member of a JWS object.
  #
  # Returns a String.
  def jwa_alg
    # https://tools.ietf.org/html/rfc7518#section-3.1
    # HMAC using SHA-256
    'HS256'
  end
end
