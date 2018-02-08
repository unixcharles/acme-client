# frozen_string_literal: true

class Acme::Client::Resources::Challenges::Base
  attr_reader :status, :url, :token, :error

  def initialize(client, **arguments)
    @client = client
    assign_attributes(arguments)
  end

  def challenge_type
    self.class::CHALLENGE_TYPE
  end

  def key_authorization
    "#{token}.#{@client.jwk.thumbprint}"
  end

  def reload
    assign_attributes **@client.challenge(url: url).to_h
    true
  end

  def request_validation
    assign_attributes **@client.request_challenge_validation(
      url: url, key_authorization: key_authorization
    ).to_h
    true
  end

  def to_h
    { status: status, url: url, token: token, error: error }
  end

  private

  def assign_attributes(status:, url:, token:, error: nil)
    @status = status
    @url = url
    @token = token
    @error = error
  end
end
