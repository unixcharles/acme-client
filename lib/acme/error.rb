class Acme::Error < StandardError
  class NotFound < Acme::Error; end
  class BadCSR < Acme::Error; end
  class BadNonce < Acme::Error; end
  class Connection < Acme::Error; end
  class Dnssec < Acme::Error; end
  class Malformed < Acme::Error; end
  class ServerInternal < Acme::Error; end
  class Acme::Tls < Acme::Error; end
  class Unauthorized < Acme::Error; end
  class UnknownHost < Acme::Error; end
end
