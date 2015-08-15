class Acme::Resources::Challenges::SimpleHttp
  CONTENT_TYPE = 'application/jose+json'

  attr_reader :status, :uri, :token, :error
  attr_accessor :tls

  def initialize(client, attributes)
    @client = client
    assign_attributes(attributes)
  end

  def content_type
    CONTENT_TYPE
  end

  def file_content
    message = { 'type' => 'simpleHttp', 'token' => token, 'tls' => tls }
    crypto.generate_signed_jws(header: {}, payload: message)
  end

  def filename
    ".well-known/acme-challenge/#{token}"
  end

  def request_verification
    response = @client.connection.post(@uri, { resource: 'challenge', type: 'simpleHttp', tls: tls })
    response.success?
  end

  def verify_status
    response = @client.connection.get(@uri)

    assign_attributes(response.body)
    @error = response.body['error']
    status
  end

  private

  def assign_attributes(attributes)
    @status = attributes.fetch('status', 'pending')
    @uri = attributes.fetch('uri')
    @token = attributes.fetch('token')
    @tls = attributes.fetch('tls')
  end

  def crypto
    @crypto ||= Acme::Crypto.new(@client.private_key)
  end
end
