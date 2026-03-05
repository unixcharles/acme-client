class Acme::Client::Error::RateLimited < Acme::Client::Error::ServerError
  attr_reader :retry_after

  DEFAULT_MESSAGE = 'Error message: urn:ietf:params:acme:error:rateLimited'

  def initialize(message = DEFAULT_MESSAGE, retry_after = 10, acme_error_body: nil)
    super(message, acme_error_body: acme_error_body)
    @retry_after = retry_after.nil? ? 10 : retry_after.to_i
  end
end
