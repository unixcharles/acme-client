module Acme::Client::JWK
  # Make a JWK from a private key.
  #
  # private_key - An OpenSSL::PKey::EC or OpenSSL::PKey::RSA instance.
  #
  # Returns a JWK::Base subclass instance.
  def self.from_private_key(private_key)
    case private_key
    when OpenSSL::PKey::RSA
      Acme::Client::JWK::RSA.new(private_key)
    when OpenSSL::PKey::EC
      Acme::Client::JWK::ECDSA.new(private_key)
    else
      raise ArgumentError, 'private_key must be EC or RSA'
    end
  end
end

require 'acme/client/jwk/base'
require 'acme/client/jwk/rsa'
require 'acme/client/jwk/ecdsa'
