# frozen_string_literal: true

class Acme::Client::Resources::Challenges::DNSAccount01 < Acme::Client::Resources::Challenges::Base
  CHALLENGE_TYPE = 'dns-account-01'.freeze
  RECORD_PREFIX = '_acme-challenge_'.freeze
  RECORD_TYPE = 'TXT'.freeze
  DIGEST = OpenSSL::Digest::SHA256
  BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567'.freeze

  def record_name
    digest = DIGEST.digest(@client.kid)[0, 10]
    bits = digest.unpack1('B*')
    label = bits.scan(/.{5}/).map { |chunk| BASE32_ALPHABET[chunk.to_i(2)] }.join
    "#{RECORD_PREFIX}#{label}"
  end

  def record_type
    RECORD_TYPE
  end

  def record_content
    Acme::Client::Util.urlsafe_base64(DIGEST.digest(key_authorization))
  end
end

