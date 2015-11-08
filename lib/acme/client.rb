class Acme::Client
  DEFAULT_ENDPOINT = 'http://127.0.0.1:4000'
  DIRECTORY_DEFAULT = {
    'new-authz' => '/acme/new-authz',
    'new-cert' => '/acme/new-cert',
    'new-reg' => '/acme/new-reg',
    'revoke-cert' => '/acme/revoke-cert'
  }

  def initialize(private_key:, endpoint: DEFAULT_ENDPOINT, directory_uri: nil)
    @endpoint, @private_key, @directory_uri = endpoint, private_key, directory_uri
    @nonces ||= []
    load_directory!
  end

  attr_reader :private_key, :nonces, :operation_endpoints

  def register(contact:)
    payload = {
      resource: 'new-reg', contact: [contact]
    }

    response = connection.post(@operation_endpoints.fetch('new-reg'), payload)
    ::Acme::Resources::Registration.new(self, response)
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
    ::Acme::Resources::Authorization.new(self, response)
  end

  def new_certificate(csr)
    payload = {
      resource: 'new-cert',
      csr: Base64.urlsafe_encode64(csr.to_der)
    }

    response = connection.post(@operation_endpoints.fetch('new-cert'), payload)
    OpenSSL::X509::Certificate.new(response.body)
  end

  def connection
    @connection ||= Faraday.new(@endpoint) do |configuration|
      configuration.use Acme::FaradayMiddleware, client: self
      configuration.adapter Faraday.default_adapter
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
