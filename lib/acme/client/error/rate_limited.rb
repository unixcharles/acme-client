class Acme::Client::Error::RateLimited < Acme::Client::Error::ServerError
  DEFAULT_MESSAGE = 'Error message: urn:ietf:params:acme:error:rateLimited'
  DEFAULT_RETRY_SECONDS = 10

  def initialize(message = DEFAULT_MESSAGE, retry_after = nil, acme_error_body: nil, subproblems: nil)
    int_retry_after = retry_after.nil? ? DEFAULT_RETRY_SECONDS : retry_after.to_i
    retry_after_time = case retry_after
                       when Time then retry_after
                       when nil then Time.now + DEFAULT_RETRY_SECONDS
                       else Acme::Client::Util.parse_retry_after(retry_after) || Time.now + DEFAULT_RETRY_SECONDS
                       end
    super(message, retry_after: int_retry_after, acme_error_body: acme_error_body, subproblems: subproblems)
    @retry_after_time = retry_after_time
  end
end
