# frozen_string_literal: true

module Acme::Client::Resources::Eab
  class Error < Exception; end
  attr_reader :kid, :hmac_key, :endpoint

  def initialize(eab_config, endpoint:)
    @kid = eab_config[:kid]
    @hmac_key = eab_config[:hmac_key]
    @endpoint = endpoint
  end

  def build_external_account_binding
    validate_eab_config!

    {
      protected: protected,
      payload: encoded_payload,
      signature: encoded_signature
    }
  end

  private

  def validate_eab_config!
    raise_error_validation_missing_field!("kid") unless kid
    raise_error_validation_missing_field!("hmac_key") unless hmac_key
  end

  def raise_error_validation_missing_field!(field)
    raise Acme::Client::Resources::Eab::Error, "no #{field} supplied to eab"
  end

  def protected
    hash = {
      alg: 'HS256',
      kid: kid,
      url: endpoint_for(:new_account)
    }
    Acme::Client::Util.urlsafe_base64(hash)
  end

  def encoded_payload
    # todo
  end

  def encoded_signature
    # todo
  end
end