# frozen_string_literal: true

require 'faraday'
require 'json'
require 'openssl'
require 'digest'
require 'forwardable'
require 'base64'
require 'time'

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
    pkix: 'application/pkix-cert'
  }

  def initialize(jwk: nil, kid: nil, private_key: nil, directory: DEFAULT_DIRECTORY, connection_options: {})
    if jwk.nil? && private_key.nil?
      raise ArgumentError, 'must specify jwk or private_key'
    end

    @jwk = if jwk
      jwk
    else
      Acme::Client::JWK.from_private_key(private_key)
    end

    @kid, @directory_url, @connection_options = kid, URI(directory), connection_options
    @nonces ||= []
  end

  attr_reader :jwk, :nonces, :directory

  def new_account(contact:, terms_of_service_agreed: nil)
    payload = {
      contact: Array(contact)
    }

    if terms_of_service_agreed
      payload[:termsOfServiceAgreed] = terms_of_service_agreed
    end

    response = post(endpoint_for('newAccount'), payload: payload, mode: :jws)
    @kid = response.headers.fetch(:location)

    if response.body.nil? || response.body.empty?
      account
    else
      arguments = Acme::Client::Resources::Account.arguments_from_response(response)
      Acme::Client::Resources::Account.new(self, url: @kid, **arguments)
    end
  end

  def account_update(contact: nil, terms_of_service_agreed: nil)
    payload = {}
    payload[:contact] = Array(contact) if contact
    payload[:termsOfServiceAgreed] = terms_of_service_agreed if terms_of_service_agreed

    response = post(kid, payload: payload)
    arguments = Acme::Client::Resources::Account.arguments_from_response(response)
    Acme::Client::Resources::Account.new(self, url: kid, **arguments)
  end

  def account_deactivate
    response = post(kid, payload: { status: 'deactivated' })
    arguments = Acme::Client::Resources::Account.arguments_from_response(response)
    Acme::Client::Resources::Account.new(self, url: kid, **arguments)
  end

  def account
    @kid ||= begin
      response = post(endpoint_for('newAccount'), payload: { onlyReturnExisting: true }, mode: :jwk)
      response.headers.fetch(:location)
    end

    response = post(@kid)
    arguments = Acme::Client::Resources::Account.arguments_from_response(response)
    Acme::Client::Resources::Account.new(self, url: @kid, **arguments)
  end

  def kid
    @kid ||= account.kid
  end

  def new_order(identifiers:, not_before: nil, not_after: nil)
    payload = {}
    payload['identifiers'] = if identifiers.is_a?(Hash)
      identifiers
    else
      Array(identifiers).map do |identifier|
        { type: 'dns', value: identifier }
      end
    end
    payload['notBefore'] = not_before if not_before
    payload['notAfter'] = not_after if not_after

    response = post(endpoint_for('newOrder'), payload: payload)
    arguments = Acme::Client::Resources::Order.arguments_from_response(response)
    Acme::Client::Resources::Order.new(self, **arguments)
  end

  def order(url:)
    response = get(url)
    arguments = Acme::Client::Resources::Order.arguments_from_response(response)
    Acme::Client::Resources::Order.new(self, **arguments)
  end

  def finalize(url:, csr:)
    unless csr.respond_to?(:to_der)
      raise ArgumentError, 'csr must respond to `#to_der`'
    end

    base64_der_csr = Acme::Client::Util.urlsafe_base64(csr.to_der)
    response = post(url, payload: { csr: base64_der_csr })
    arguments = Acme::Client::Resources::Order.arguments_from_response(response)
    Acme::Client::Resources::Order.new(self, **arguments)
  end

  def certificate(url:)
    download(url).body
  end

  def authorization(url:)
    response = get(url)
    arguments = Acme::Client::Resources::Authorization.arguments_from_response(response)
    Acme::Client::Resources::Authorization.new(self, url: url, **arguments)
  end

  def deactivate_authorization(url:)
    response = post(url, payload: { status: 'deactivated' })
    arguments = Acme::Client::Resources::Authorization.arguments_from_response(response)
    Acme::Client::Resources::Authorization.new(self, url: url, **arguments)
  end

  def challenge(url:)
    response = get(url)
    arguments = Acme::Client::Resources::Challenges.arguments_from_response(response)
    Acme::Client::Resources::Challenges.new(self, **arguments)
  end

  def request_challenge_validation(url:, key_authorization:)
    response = post(url, payload: { keyAuthorization: key_authorization })
    arguments = Acme::Client::Resources::Challenges.arguments_from_response(response)
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

    response = post(endpoint_for('revokeCert'), payload: payload)
    response.success?
  end

  def get_nonce
    response = Faraday.head(endpoint_for('newNonce'), nil, 'User-Agent' => USER_AGENT)
    nonces << response.headers['replay-nonce']
    true
  end

  private

  def post(url, payload: {}, mode: :kid)
    connection = connection_for(url: url, mode: mode)
    connection.post(url, payload)
  end

  def get(url, mode: :kid)
    connection = connection_for(url: url, mode: mode)
    connection.get(url)
  end

  def download(url)
    connection = connection_for(url: url, mode: :download)
    connection.get do |request|
      request.url(url)
      request.headers['Accept'] = CONTENT_TYPES.fetch(:pkix)
    end
  end

  def connection_for(url:, mode:)
    uri = URI(url)
    endpoint = "#{uri.scheme}://#{uri.hostname}:#{uri.port}"
    @connections ||= {}
    @connections[mode] ||= {}
    @connections[mode][endpoint] ||= new_connection(endpoint: endpoint, mode: mode)
  end

  def new_connection(endpoint:, mode:)
    Faraday.new(endpoint, **@connection_options) do |configuration|
      configuration.use Acme::Client::FaradayMiddleware, client: self, mode: mode
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
    load_directory! unless @directory_loaded
    @directory.fetch(key) do |missing_key|
      raise Acme::Client::Error::UnsupporedOperation,
        "Directory at #{@directory_url} does not include `#{missing_key}`"
    end
  end

  def load_directory!
    return false if @directory_loaded
    body = fetch_directory
    @meta = body['meta']

    @directory = {}
    @directory['newNonce'] = URI(body['newNonce']) if body['newNonce']
    @directory['newAccount'] = URI(body['newAccount']) if body['newAccount']
    @directory['newOrder'] = URI(body['newOrder']) if body['newOrder']
    @directory['newAuthz'] = URI(body['newAuthz']) if body['newAuthz']
    @directory['revokeCert'] = URI(body['revokeCert']) if body['revokeCert']
    @directory['keyChange'] = URI(body['keyChange']) if body['keyChange']

    @directory_loaded = true
  rescue JSON::ParserError => exception
    raise InvalidDirectory, "Invalid directory url\n#{@directory} did not return a valid directory\n#{exception.inspect}"
  end

  def fetch_directory
    connection = Faraday.new(url: @directory)
    connection.headers[:user_agent] = USER_AGENT
    response = connection.get(@directory_url)
    JSON.parse(response.body)
  end
end
