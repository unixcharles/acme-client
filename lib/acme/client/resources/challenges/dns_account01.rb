# frozen_string_literal: true

# DNS-Account-01 challenge implementation following draft-ietf-acme-dns-account-label-01
# Creates account-specific DNS record names to enable concurrent domain validation
class Acme::Client::Resources::Challenges::DNSAccount01 < Acme::Client::Resources::Challenges::Base
  CHALLENGE_TYPE = 'dns-account-01'.freeze
  RECORD_PREFIX = '_'.freeze
  RECORD_SUFFIX = '._acme-challenge'.freeze
  RECORD_TYPE = 'TXT'.freeze
  DIGEST = OpenSSL::Digest::SHA256
  BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567'.freeze

  # Generates account-specific DNS record name using SHA256(account_url) + Base32
  # Format: _<base32_label>._acme-challenge
  def record_name
    digest = DIGEST.digest(@client.kid)[0, 10]
    bits = digest.unpack1('B*')
    label = bits.scan(/.{5}/).map { |chunk| BASE32_ALPHABET[chunk.to_i(2)] }.join
    "#{RECORD_PREFIX}#{label}#{RECORD_SUFFIX}"
  end

  def record_type
    RECORD_TYPE
  end

  def record_content
    Acme::Client::Util.urlsafe_base64(DIGEST.digest(key_authorization))
  end
end

