class Acme::Client::Error < StandardError
  attr_reader :retry_after, :subproblems

  Subproblem = Struct.new(:type, :detail, :identifier, keyword_init: true) do
    def to_h
      { type: type, detail: detail, identifier: identifier }
    end
  end

  def initialize(message = nil, retry_after: nil, subproblems: nil)
    super(message)
    @retry_after = retry_after
    @subproblems = parse_subproblems(subproblems)
  end

  private

  def parse_subproblems(raw)
    return [] if raw.nil? || !raw.is_a?(Array)

    raw.map do |sp|
      Subproblem.new(
        type: sp['type'],
        detail: sp['detail'],
        identifier: sp['identifier']
      )
    end
  end

  public

  class Timeout < Acme::Client::Error; end

  class ClientError < Acme::Client::Error; end
  class InvalidDirectory < ClientError; end
  class UnsupportedOperation < ClientError; end
  class UnsupportedChallengeType < ClientError; end
  class NotFound < ClientError; end
  class CertificateNotReady < ClientError; end
  class ForcedChainNotFound < ClientError; end
  class OrderNotReady < ClientError; end
  class OrderUrlNil < ClientError; end

  class ServerError < Acme::Client::Error; end
  class AlreadyReplaced < ServerError; end
  class AlreadyRevoked < ServerError; end
  class BadCSR < ServerError; end
  class BadNonce < ServerError; end
  class BadPublicKey < ServerError; end
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

  ACME_ERRORS = {
    'urn:ietf:params:acme:error:alreadyReplaced' => AlreadyReplaced,
    'urn:ietf:params:acme:error:alreadyRevoked' => AlreadyRevoked,
    'urn:ietf:params:acme:error:badCSR' => BadCSR,
    'urn:ietf:params:acme:error:badNonce' => BadNonce,
    'urn:ietf:params:acme:error:badPublicKey' => BadPublicKey,
    'urn:ietf:params:acme:error:badSignatureAlgorithm' => BadSignatureAlgorithm,
    'urn:ietf:params:acme:error:invalidContact' => InvalidContact,
    'urn:ietf:params:acme:error:unsupportedContact' => UnsupportedContact,
    'urn:ietf:params:acme:error:externalAccountRequired' => ExternalAccountRequired,
    'urn:ietf:params:acme:error:accountDoesNotExist' => AccountDoesNotExist,
    'urn:ietf:params:acme:error:malformed' => Malformed,
    'urn:ietf:params:acme:error:orderNotReady' => OrderNotReady,
    'urn:ietf:params:acme:error:rateLimited' => RateLimited,
    'urn:ietf:params:acme:error:rejectedIdentifier' => RejectedIdentifier,
    'urn:ietf:params:acme:error:serverInternal' => ServerInternal,
    'urn:ietf:params:acme:error:unauthorized' => Unauthorized,
    'urn:ietf:params:acme:error:unsupportedIdentifier' => UnsupportedIdentifier,
    'urn:ietf:params:acme:error:userActionRequired' => UserActionRequired,
    'urn:ietf:params:acme:error:badRevocationReason' => BadRevocationReason,
    'urn:ietf:params:acme:error:caa' => Caa,
    'urn:ietf:params:acme:error:dns' => Dns,
    'urn:ietf:params:acme:error:connection' => Connection,
    'urn:ietf:params:acme:error:tls' => Tls,
    'urn:ietf:params:acme:error:incorrectResponse' => IncorrectResponse
  }
end
