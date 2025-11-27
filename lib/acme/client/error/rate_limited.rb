class Acme::Client::Error::RateLimited < Acme::Client::Error::ServerError
  attr_reader :retry_after

  def initialize(message, retry_after = 10)
    super(message)
    @retry_after = retry_after.nil? ? 10 : retry_after.to_i
  end
end
