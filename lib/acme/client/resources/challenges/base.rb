# frozen_string_literal: true

class Acme::Client::Resources::Challenges::Base
  attr_reader :status, :url, :token, :error, :validated

  def initialize(client, **arguments)
    @client = client
    assign_attributes(**arguments)
  end

  def challenge_type
    self.class::CHALLENGE_TYPE
  end

  def key_authorization
    "#{token}.#{@client.jwk.thumbprint}"
  end

  def reload
    assign_attributes(**@client.challenge(url: url).to_h)
    true
  end

  def request_validation
    assign_attributes(**send_challenge_validation(
      url: url
    ))
    true
  end

  def to_h
    { status: status, url: url, token: token, error: error, validated: validated }
  end

  private

  def send_challenge_validation(url:)
    @client.request_challenge_validation(
      url: url
    ).to_h
  end

  def assign_attributes(status:, url:, token:, error: nil, validated: nil)
    @status = status
    @url = url
    @token = token
    @error = error
    @validated = validated
  end
end
