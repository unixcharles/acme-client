class Acme::Client::FaradayMiddleware < Faraday::Middleware
  attr_reader :env, :response, :client

  def initialize(app, client:)
    super(app)
    @client = client
  end

  def call(env)
    @env = env
    @env[:request_headers]['User-Agent'] = user_agent
    @env.body = crypto.generate_signed_jws(header: { nonce: pop_nonce }, payload: env.body)
    @app.call(env).on_complete { |response_env| on_complete(response_env) }
  rescue Faraday::TimeoutError
    raise Acme::Client::Error::Timeout
  end

  def on_complete(env)
    @env = env

    raise_on_not_found!
    store_nonce
    env.body = decode_body
    env.response_headers['Link'] = decode_link_headers

    return if env.success?

    raise_on_error!
  end

  private

  def user_agent
    "Acme::Client v#{Acme::Client::VERSION} (https://github.com/unixcharles/acme-client)"
  end

  def raise_on_not_found!
    raise Acme::Client::Error::NotFound, env.url.to_s if env.status == 404
  end

  def raise_on_error!
    raise error_class, error_message
  end

  def error_message
    if env.body.is_a? Hash
      env.body['detail']
    else
      "Error message: #{env.body}"
    end
  end

  def error_class
    if error_name.present? && Acme::Client::Error.qualified_const_defined?(error_name)
      "Acme::Client::Error::#{error_name}".constantize
    else
      Acme::Client::Error
    end
  end

  def error_name
    @error_name ||= begin
      return unless env.body.is_a?(Hash)
      return unless env.body.key?('type')

      env.body['type'].gsub('urn:acme:error:', '').classify
    end
  end

  def decode_body
    content_type = env.response_headers['Content-Type']

    if content_type == 'application/json' || content_type == 'application/problem+json'
      JSON.load(env.body)
    else
      env.body
    end
  end

  LINK_MATCH = /<(.*?)>;rel="([\w-]+)"/

  def decode_link_headers
    return unless env.response_headers.key?('Link')
    link_header = env.response_headers['Link']

    links = link_header.split(', ').map { |entry|
      _, link, name = *entry.match(LINK_MATCH)
      [name, link]
    }

    Hash[*links.flatten]
  end

  def store_nonce
    nonces << env.response_headers['replay-nonce']
  end

  def pop_nonce
    if nonces.empty?
      get_nonce
    else
      nonces.pop
    end
  end

  def get_nonce
    response = Faraday.head(env.url, nil, 'User-Agent' => user_agent)
    response.headers['replay-nonce']
  end

  def nonces
    client.nonces
  end

  def private_key
    client.private_key
  end

  def crypto
    @crypto ||= Acme::Client::Crypto.new(private_key)
  end
end
