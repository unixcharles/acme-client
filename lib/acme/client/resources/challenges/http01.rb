# frozen_string_literal: true

class Acme::Client::Resources::Challenges::HTTP01 < Acme::Client::Resources::Challenges::Base
  CHALLENGE_TYPE = 'http-01'.freeze
  CONTENT_TYPE = 'text/plain'.freeze

  def content_type
    CONTENT_TYPE
  end

  def file_content
    authorization_key
  end

  def filename
    ".well-known/acme-challenge/#{token}"
  end
end
