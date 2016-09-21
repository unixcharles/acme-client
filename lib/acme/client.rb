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
require 'acme/client/crypto'
require 'acme/client/resources'
require 'acme/client/faraday_middleware'
require 'acme/client/error'

class Acme::Client
  DEFAULT_ENDPOINT = 'http://127.0.0.1:4000'.freeze
  DIRECTORY_DEFAULT = {
    'new-authz' => '/acme/new-authz',
    'new-cert' => '/acme/new-cert',
    'new-reg' => '/acme/new-reg',
    'revoke-cert' => '/acme/revoke-cert'
  }.freeze

  def initialize(private_key:, endpoint: DEFAULT_ENDPOINT, directory_uri: nil, connection_options: {})
    @endpoint, @private_key, @directory_uri, @connection_options = endpoint, private_key, directory_uri, connection_options
    @nonces ||= []
    load_directory!
  end

  attr_reader :private_key, :nonces, :endpoint, :directory_uri, :operation_endpoints

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
