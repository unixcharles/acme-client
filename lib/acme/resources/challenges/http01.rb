class Acme::Resources::Challenges::HTTP01 < Acme::Resources::Challenges::Base
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

  def request_verification
    response = client.connection.post(@uri, { resource: 'challenge', type: 'http-01', keyAuthorization: authorization_key })
    response.success?
  end
end
