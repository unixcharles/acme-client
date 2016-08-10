# frozen_string_literal: true

class Acme::Client::Resources::Challenges::DNS01 < Acme::Client::Resources::Challenges::Base
  CHALLENGE_TYPE = 'dns-01'.freeze
  RECORD_NAME = '_acme-challenge'.freeze
  RECORD_TYPE = 'TXT'.freeze

  def record_name
    RECORD_NAME
  end

  def record_type
    RECORD_TYPE
  end

  def record_content
    Base64.urlsafe_encode64(crypto.digest.digest(authorization_key)).sub(/[\s=]*\z/, '')
  end
end
