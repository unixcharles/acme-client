module RetryHelper
  def retry_until(condition:, retry_count: 3, wait: 0.25)
    count = 0
    until condition.call
      yield
      count =+ 1
      raise 'timed out' if count > retry_count
    end
  end
end
