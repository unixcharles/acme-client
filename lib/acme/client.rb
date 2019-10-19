# frozen_string_literal: true

require 'faraday'
require 'json'
require 'openssl'
require 'digest'
require 'forwardable'
require 'base64'
require 'time'
require 'uri'

module Acme; end
class Acme::Client; end

require 'acme/client/version'
require 'acme/client/certificate_request'
require 'acme/client/self_sign_certificate'
require 'acme/client/resources'
require 'acme/client/faraday_middleware'
require 'acme/client/jwk'
require 'acme/client/error'
require 'acme/client/util'

class Acme::Client
  DEFAULT_DIRECTORY = 'http://127.0.0.1:4000/directory'.freeze
  repo_url = 'https://github.com/unixcharles/acme-client'
  USER_AGENT = "Acme::Client v#{Acme::Client::VERSION} (#{repo_url})".freeze
  CONTENT_TYPES = {
    pem: 'application/pem-certificate-chain'
  }

  class << self
    def prepare_order_identifiers(identifiers)
      if identifiers.is_a?(Hash)
        [identifiers]
      else
        Array(identifiers).map do |identifier|
          identifier.is_a?(String) ? { type: 'dns', value: identifier } : identifier
        end
      end
    end
  end

  def initialize(jwk: nil, kid: nil, private_key: nil, directory: DEFAULT_DIRECTORY, connection_options: {}, bad_nonce_retry: 0)
    if jwk.nil? && private_key.nil?
      raise ArgumentError, 'must specify jwk or private_key'
    end

    @jwk = if jwk
      jwk
    else
      Acme::Client::JWK.from_private_key(private_key)
    end

    @kid, @connection_options = kid, connection_options
    @bad_nonce_retry = bad_nonce_retry
    @directory = Acme::Client::Resources::Directory.new(URI(directory), @connection_options)
    @nonces ||= []
  end

  attr_reader :jwk, :nonces

  def new_account(contact:, terms_of_service_agreed: nil)
    payload = {
      contact: Array(contact)
    }

    if terms_of_service_agreed
      payload[:termsOfServiceAgreed] = terms_of_service_agreed
    end

    response = post(endpoint_for(:new_account), payload: payload, mode: :jws)
    @kid = response.headers.fetch(:location)

    if response.body.nil? || response.body.empty?
      account
    else
      arguments = attributes_from_account_response(response)
      Acme::Client::Resources::Account.new(self, url: @kid, **arguments)
    end
  end

  def account_update(contact: nil, terms_of_service_agreed: nil)
    payload = {}
    payload[:contact] = Array(contact) if contact
    payload[:termsOfServiceAgreed] = terms_of_service_agreed if terms_of_service_agreed

    response = post(kid, payload: payload)
    arguments = attributes_from_account_response(response)
    Acme::Client::Resources::Account.new(self, url: kid, **arguments)
  end

  def account_deactivate
    response = post(kid, payload: { status: 'deactivated' })
    arguments = attributes_from_account_response(response)
    Acme::Client::Resources::Account.new(self, url: kid, **arguments)
  end

  def account
    @kid ||= begin
      response = post(endpoint_for(:new_account), payload: { onlyReturnExisting: true }, mode: :jwk)
      response.headers.fetch(:location)
    end

    response = post_as_get(@kid)
    arguments = attributes_from_account_response(response)
    Acme::Client::Resources::Account.new(self, url: @kid, **arguments)
  end

  def kid
    @kid ||= account.kid
  end

  def new_order(identifiers:, not_before: nil, not_after: nil)
    payload = {}
    payload['identifiers'] = self.class.prepare_order_identifiers(identifiers)
    payload['notBefore'] = not_before if not_before
    payload['notAfter'] = not_after if not_after

    response = post(endpoint_for(:new_order), payload: payload)
    arguments = attributes_from_order_response(response)
    Acme::Client::Resources::Order.new(self, **arguments)
  end

  def order(url:)
    response = post_as_get(url)
    arguments = attributes_from_order_response(response)
    Acme::Client::Resources::Order.new(self, **arguments.merge(url: url))
  end

  def finalize(url:, csr:)
    unless csr.respond_to?(:to_der)
      raise ArgumentError, 'csr must respond to `#to_der`'
    end

    base64_der_csr = Acme::Client::Util.urlsafe_base64(csr.to_der)
    response = post(url, payload: { csr: base64_der_csr })
    arguments = attributes_from_order_response(response)
    Acme::Client::Resources::Order.new(self, **arguments)
  end

  def certificate(url:)
    response = download(url, format: :pem)
    response.body
  end

  def authorization(url:)
    response = post_as_get(url)
    arguments = attributes_from_authorization_response(response)
    Acme::Client::Resources::Authorization.new(self, url: url, **arguments)
  end

  def deactivate_authorization(url:)
    response = post(url, payload: { status: 'deactivated' })
    arguments = attributes_from_authorization_response(response)
    Acme::Client::Resources::Authorization.new(self, url: url, **arguments)
  end

  def challenge(url:)
    response = post_as_get(url)
    arguments = attributes_from_challenge_response(response)
    Acme::Client::Resources::Challenges.new(self, **arguments)
  end

  def request_challenge_validation(url:, key_authorization:)
    response = post(url, payload: {})
    arguments = attributes_from_challenge_response(response)
    Acme::Client::Resources::Challenges.new(self, **arguments)
  end

  def revoke(certificate:, reason: nil)
    der_certificate = if certificate.respond_to?(:to_der)
      certificate.to_der
    else
      OpenSSL::X509::Certificate.new(certificate).to_der
    end

    base64_der_certificate = Acme::Client::Util.urlsafe_base64(der_certificate)
    payload = { certificate: base64_der_certificate }
    payload[:reason] = reason unless reason.nil?

    response = post(endpoint_for(:revoke_certificate), payload: payload)
    response.success?
  end

  def get_nonce
    connection = new_connection(endpoint: endpoint_for(:new_nonce))
    response = connection.head(nil, nil, 'User-Agent' => USER_AGENT)
    nonces << response.headers['replay-nonce']
    true
  end

  def meta
    @directory.meta
  end

  def terms_of_service
    @directory.terms_of_service
  end

  def website
    @directory.website
  end

  def caa_identities
    @directory.caa_identities
  end

  def external_account_required
    @directory.external_account_required
  end

  private

  def attributes_from_account_response(response)
    extract_attributes(
      response.body,
      :status,
      [:term_of_service, 'termsOfServiceAgreed'],
      :contact
    )
  end

  def attributes_from_order_response(response)
    attributes = extract_attributes(
      response.body,
      :status,
      :expires,
      [:finalize_url, 'finalize'],
      [:authorization_urls, 'authorizations'],
      [:certificate_url, 'certificate'],
      :identifiers
    )

    attributes[:url] = response.headers[:location] if response.headers[:location]
    attributes
  end

  def attributes_from_authorization_response(response)
    extract_attributes(response.body, :identifier, :status, :expires, :challenges, :wildcard)
  end

  def attributes_from_challenge_response(response)
    extract_attributes(response.body, :status, :url, :token, :type, :error)
  end

  def extract_attributes(input, *attributes)
    attributes
      .map {|fields| Array(fields) }
      .each_with_object({}) { |(key, field), hash|
      field ||= key.to_s
      hash[key] = input[field]
    }
  end

  def post(url, payload: {}, mode: :kid)
    connection = connection_for(url: url, mode: mode)
    connection.post(url, payload)
  end

  def post_as_get(url, mode: :kid)
    connection = connection_for(url: url, mode: mode)
    connection.post(url, nil)
  end

  def get(url, mode: :kid)
    connection = connection_for(url: url, mode: mode)
    connection.get(url)
  end

  def download(url, format:)
    connection = connection_for(url: url, mode: :kid)
    connection.post do |request|
      request.url(url)
      request.headers['Accept'] = CONTENT_TYPES.fetch(format)
    end
  end

  def connection_for(url:, mode:)
    uri = URI(url)
    endpoint = "#{uri.scheme}://#{uri.hostname}:#{uri.port}"
    @connections ||= {}
    @connections[mode] ||= {}
    @connections[mode][endpoint] ||= new_acme_connection(endpoint: endpoint, mode: mode)
  end

  def new_acme_connection(endpoint:, mode:)
    new_connection(endpoint: endpoint) do |configuration|
      configuration.use Acme::Client::FaradayMiddleware, client: self, mode: mode
    end
  end

  def new_connection(endpoint:)
    Faraday.new(endpoint, **@connection_options) do |configuration|
      if @bad_nonce_retry > 0
        configuration.request(:retry,
          max: @bad_nonce_retry,
          methods: Faraday::Connection::METHODS,
          exceptions: [Acme::Client::Error::BadNonce])
      end
      yield(configuration) if block_given?
      configuration.adapter Faraday.default_adapter
    end
  end

  def fetch_chain(response, limit = 10)
    links = response.headers['link']
    if limit.zero? || links.nil? || links['up'].nil?
      []
    else
      issuer = get(links['up'])
      [OpenSSL::X509::Certificate.new(issuer.body), *fetch_chain(issuer, limit - 1)]
    end
  end

  def endpoint_for(key)
    @directory.endpoint_for(key)
  end
end
