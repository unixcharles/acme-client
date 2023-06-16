# frozen_string_literal: true

class Acme::Client::Resources::Authorization
  attr_reader :url, :identifier, :domain, :expires, :status, :wildcard

  def initialize(client, **arguments)
    @client = client
    assign_attributes(**arguments)
  end

  def deactivate
    assign_attributes(**@client.deactivate_authorization(url: url).to_h)
    true
  end

  def reload
    assign_attributes(**@client.authorization(url: url).to_h)
    true
  end

  def challenges
    @challenges.map do |challenge|
      initialize_challenge(challenge)
    end
  end

  def http01
    @http01 ||= challenges.find { |challenge|
      challenge.is_a?(Acme::Client::Resources::Challenges::HTTP01)
    }
  end
  alias_method :http, :http01

  def dns01
    @dns01 ||= challenges.find { |challenge|
      challenge.is_a?(Acme::Client::Resources::Challenges::DNS01)
    }
  end
  alias_method :dns, :dns01

  def to_h
    {
      url: url,
      identifier: identifier,
      status: status,
      expires: expires,
      challenges: @challenges,
      wildcard: wildcard
    }
  end

  private

  def initialize_challenge(attributes)
    arguments = {
      type: attributes.fetch('type'),
      status: attributes.fetch('status'),
      url: attributes.fetch('url'),
      token: attributes.fetch('token'),
      error: attributes['error']
    }
    Acme::Client::Resources::Challenges.new(@client, **arguments)
  end

  def assign_attributes(url:, status:, expires:, challenges:, identifier:, wildcard: false)
    @url = url
    @identifier = identifier
    @domain = identifier.fetch('value')
    @status = status
    @expires = expires
    @challenges = challenges
    @wildcard = wildcard
  end
end
