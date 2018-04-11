class Acme::Client::Error < StandardError
  class Timeout < Acme::Client::Error; end

  class ClientError < Acme::Client::Error; end
  class InvalidDirectory < ClientError; end
  class UnsupportedOperation < ClientError; end
  class UnsupportedChallengeType < ClientError; end
  class NotFound < ClientError; end
  class CertificateNotReady < ClientError; end

  class ServerError < Acme::Client::Error; end
  class BadCSR < ServerError; end
  class BadNonce < ServerError; end
  class BadSignatureAlgorithm < ServerError; end
  class InvalidContact < ServerError; end
  class UnsupportedContact < ServerError; end
  class ExternalAccountRequired < ServerError; end
  class AccountDoesNotExist < ServerError; end
  class Malformed < ServerError; end
  class RateLimited < ServerError; end
  class RejectedIdentifier < ServerError; end
  class ServerInternal < ServerError; end
  class Unauthorized < ServerError; end
  class UnsupportedIdentifier < ServerError; end
  class UserActionRequired < ServerError; end
  class BadRevocationReason < ServerError; end
  class Caa < ServerError; end
  class Dns < ServerError; end
  class Connection < ServerError; end
  class Tls < ServerError; end
  class IncorrectResponse < ServerError; end
end
