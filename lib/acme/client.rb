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
require 'acme/client/certificate'
require 'acme/client/certificate_request'
require 'acme/client/self_sign_certificate'
require 'acme/client/resources'
require 'acme/client/faraday_middleware'
require 'acme/client/jwk'
require 'acme/client/error'
require 'acme/client/error/rate_limited'
require 'acme/client/util'

class Acme::Client
  DEFAULT_ENDPOINT = 'http://127.0.0.1:4000'.freeze
  DIRECTORY_DEFAULT = {
    'new-authz' => '/acme/new-authz',
    'new-cert' => '/acme/new-cert',
    'new-reg' => '/acme/new-reg',
    'revoke-cert' => '/acme/revoke-cert'
  }.freeze

  def initialize(jwk: nil, private_key: nil, endpoint: DEFAULT_ENDPOINT, directory_uri: nil, connection_options: {})
    if jwk.nil? && private_key.nil?
      raise ArgumentError, 'must specify jwk or private_key'
    end

    @jwk = if jwk
      jwk
    else
      Acme::Client::JWK.from_private_key(private_key)
    end

    @endpoint, @directory_uri, @connection_options = endpoint, directory_uri, connection_options
    @nonces ||= []
    load_directory!
  end

  attr_reader :jwk, :nonces, :endpoint, :directory_uri, :operation_endpoints

  def register(contact:)
    payload = {
      resource: 'new-reg', contact: Array(contact)
    }

    response = connection.post(@operation_endpoints.fetch('new-reg'), payload)
    ::Acme::Client::Resources::Registration.new(self, response)
  end

  def authorize(domain:)
    payload = {
      resource: 'new-authz',
      identifier: {
        type: 'dns',
        value: domain
      }
    }

    response = connection.post(@operation_endpoints.fetch('new-authz'), payload)
    ::Acme::Client::Resources::Authorization.new(self, response.headers['Location'], response)
  end

  def fetch_authorization(uri)
    response = connection.get(uri)
    ::Acme::Client::Resources::Authorization.new(self, uri, response)
  end

  def new_certificate(csr)
    payload = {
      resource: 'new-cert',
      csr: Base64.urlsafe_encode64(csr.to_der)
    }

    response = connection.post(@operation_endpoints.fetch('new-cert'), payload)
    ::Acme::Client::Certificate.new(OpenSSL::X509::Certificate.new(response.body), response.headers['location'], fetch_chain(response), csr)
  end

  def revoke_certificate(certificate)
    payload = { resource: 'revoke-cert', certificate: Base64.urlsafe_encode64(certificate.to_der) }
    endpoint = @operation_endpoints.fetch('revoke-cert')
    response = connection.post(endpoint, payload)
    response.success?
  end

  def self.revoke_certificate(certificate, *arguments)
    client = new(*arguments)
    client.revoke_certificate(certificate)
  end

  def connection
    @connection ||= Faraday.new(@endpoint, **@connection_options) do |configuration|
      configuration.use Acme::Client::FaradayMiddleware, client: self
      configuration.adapter Faraday.default_adapter
    end
  end

  private

  def fetch_chain(response, limit = 10)
    links = response.headers['link']
    if limit.zero? || links.nil? || links['up'].nil?
      []
    else
      issuer = connection.get(links['up'])
      [OpenSSL::X509::Certificate.new(issuer.body), *fetch_chain(issuer, limit - 1)]
    end
  end

  def load_directory!
    @operation_endpoints = if @directory_uri
      response = connection.get(@directory_uri)
      body = response.body
      {
        'new-reg' => body.fetch('new-reg'),
        'new-authz' => body.fetch('new-authz'),
        'new-cert' => body.fetch('new-cert'),
        'revoke-cert' => body.fetch('revoke-cert'),
      }
    else
      DIRECTORY_DEFAULT
    end
  end
end
