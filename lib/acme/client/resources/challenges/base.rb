class Acme::Client::Resources::Challenges::Base
  attr_reader :authorization, :status, :uri, :token, :error

  def initialize(authorization)
    @authorization = authorization
  end

  def client
    authorization.client
  end

  def verify_status
    authorization.verify_status

    status
  end

  def request_verification
    response = client.connection.post(@uri, resource: 'challenge', type: challenge_type, keyAuthorization: authorization_key)
    response.success?
  end

  def assign_attributes(attributes)
    @status = attributes.fetch('status', 'pending')
    @uri = attributes.fetch('uri')
    @token = attributes.fetch('token')
    @error = attributes['error']
  end

  private

  def challenge_type
    self.class::CHALLENGE_TYPE
  end

  def authorization_key
    "#{token}.#{crypto.thumbprint}"
  end

  def crypto
    @crypto ||= Acme::Client::Crypto.new(client.private_key)
  end
end
