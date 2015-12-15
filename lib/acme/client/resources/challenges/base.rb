class Acme::Client::Resources::Challenges::Base

  attr_reader :client, :status, :uri, :token, :error

  def initialize(client, attributes)
    @client = client
    assign_attributes(attributes)
  end

  def verify_status
    response = @client.connection.get(@uri)

    assign_attributes(response.body)
    @error = response.body['error']
    status
  end

  private

  def authorization_key
    "#{token}.#{crypto.thumbprint}"
  end

  def assign_attributes(attributes)
    @status = attributes.fetch('status', 'pending')
    @uri = attributes.fetch('uri')
    @token = attributes.fetch('token')
  end

  def crypto
    @crypto ||= Acme::Client::Crypto.new(@client.private_key)
  end
end
