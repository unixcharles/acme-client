class Acme::Resources::Challenges::DNS01 < Acme::Resources::Challenges::Base
  RECORD_NAME = '_acme-challenge'.freeze
  RECORD_TYPE = 'TXT'.freeze

  def record_name
    RECORD_NAME
  end

  def record_type
    RECORD_TYPE
  end

  def record_content
    crypto.digest.hexdigest(authorization_key)
  end

  def request_verification
    response = @client.connection.post(@uri, { resource: 'challenge', type: 'dns-01', keyAuthorization: authorization_key })
    response.success?
  end
end
