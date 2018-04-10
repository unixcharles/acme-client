class Acme::Client::Error::RateLimited < Acme::Client::Error
  DEFAULT_RETRY_AFTER = 10

  def retry_after
    @env.response_headers.fetch('Retry-After', DEFAULT_RETRY_AFTER).to_i
  end
end
