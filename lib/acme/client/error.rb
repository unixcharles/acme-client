class Acme::Client::Error < StandardError
  def initialize(message = nil, env = nil)
    super(message)
    @env = env
  end

  class NotFound < Acme::Client::Error; end
  class BadCSR < Acme::Client::Error; end
  class BadNonce < Acme::Client::Error; end
  class Connection < Acme::Client::Error; end
  class Dnssec < Acme::Client::Error; end
  class Malformed < Acme::Client::Error; end
  class ServerInternal < Acme::Client::Error; end
  class Acme::Tls < Acme::Client::Error; end
  class Unauthorized < Acme::Client::Error; end
  class UnknownHost < Acme::Client::Error; end
  class Timeout < Acme::Client::Error; end
  class RejectedIdentifier < Acme::Client::Error; end
  class UnsupportedIdentifier < Acme::Client::Error; end
end
