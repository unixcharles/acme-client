# frozen_string_literal: true

class Acme::Client::Resources::Directory
  DIRECTORY_RESOURCES = {
    new_nonce: 'newNonce',
    new_account: 'newAccount',
    new_order: 'newOrder',
    new_authz: 'newAuthz',
    revoke_certificate: 'revokeCert',
    key_change: 'keyChange'
  }

  def initialize(url, connection_options)
    @url, @connection_options = url, connection_options
  end

  def endpoint_for(key)
    directory.fetch(key) do |missing_key|
      raise Acme::Client::Error::UnsupportedOperation,
        "Directory at #{@url} does not include `#{missing_key}`"
    end
  end

  def meta
    directory[:meta]
  end

  private

  def directory
    @directory ||= load_directory
  end

  def load_directory
    body = fetch_directory
    result = {}
    result[:meta] = body.delete('meta')
    DIRECTORY_RESOURCES.each do |key, entry|
      result[key] = URI(body[entry]) if body[entry]
    end
    result
  rescue JSON::ParserError => exception
    raise InvalidDirectory, "Invalid directory url\n#{@directory} did not return a valid directory\n#{exception.inspect}"
  end

  def fetch_directory
    connection = Faraday.new(url: @directory, **@connection_options)
    connection.headers[:user_agent] = Acme::Client::USER_AGENT
    response = connection.get(@url)
    JSON.parse(response.body)
  end
end
