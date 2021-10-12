# frozen_string_literal: true

require 'openssl'
class Acme::Client::Resources::Eab
  class Error < RuntimeError; end
  attr_reader :kid, :hmac_key, :endpoint
  def initialize(eab_config, endpoint:, jwk:)
    @kid = eab_config[:kid]
    @hmac_key = eab_config[:hmac_key]
    @endpoint = endpoint
    @jwk = jwk
  end

  def build_external_account_binding
    validate_eab_config!
    {   protected: protected,
        payload: encoded_payload,
        signature: encoded_signature }
  end

  private

  def validate_eab_config!
    raise_error_validation_missing_field!('kid') unless kid
    raise_error_validation_missing_field!('hmac_key') unless hmac_key
  end

  def raise_error_validation_missing_field!(field)
    raise Acme::Client::Resources::Eab::Error, "no #{field} supplied to eab"
  end

  def protected
    hash = {
      alg: 'HS256',
      kid: @kid,
      url: @endpoint
    }
    Acme::Client::Util.urlsafe_base64(hash.to_json)
  end

  def encoded_payload
    Acme::Client::Util.urlsafe_base64(@jwk.to_json)
  end

  def key
    Base64.urlsafe_decode64(@hmac_key)
  end

  def encoded_signature
    sign_t = "#{protected}.#{encoded_payload}"
    Base64.urlsafe_encode64(OpenSSL::HMAC.digest('SHA256', key, sign_t))
  end
end
