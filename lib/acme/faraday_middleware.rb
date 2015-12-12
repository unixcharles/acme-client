class Acme::FaradayMiddleware < Faraday::Middleware
  attr_reader :env, :response, :client

  def initialize(app, client:)
    super(app)
    @client = client
  end

  def call(env)
    @env = env
    @env.body = crypto.generate_signed_jws(header: { nonce: pop_nonce }, payload: env.body)
    @app.call(env).on_complete {|env| on_complete(env) }
  end

  def on_complete(env)
    raise Acme::Error::NotFound, env.url.to_s if env.status == 404

    nonces << env.response_headers['replay-nonce']

    content_type = env.response_headers['Content-Type']

    if content_type == 'application/json' || content_type == 'application/problem+json'
      env.body = JSON.load(env.body)
    end

    if env.response_headers.key?('Link')
      link_header = env.response_headers['Link']
      links = link_header.split(', ').map do |entry|
        link = entry.match(/<(.*?)>;/).captures.first
        name = entry.match(/rel="([\w-]+)"/).captures.first
        [name, link]
      end

      env.response_headers['Link'] = Hash[*links.flatten]
    end

    return if env.success?

    error_name = env.body['type'].gsub('urn:acme:error:', '').classify
    error_class = if Acme::Error.qualified_const_defined?(error_name)
      "Acme::Error::#{error_name}".constantize
    else
      Acme::Error
    end

    if env.body.is_a? Hash
      env.body['detail']
    else
      "Error message: #{env.body}"
    end

    raise error_class, env.body['detail']
  end

  private

  def pop_nonce
    if nonces.empty?
      get_nonce
    else
      nonces.pop
    end
  end

  def get_nonce
    response = Faraday.head(env.url)
    response.headers['replay-nonce']
  end

  def nonces
    client.nonces
  end

  def private_key
    client.private_key
  end

  def crypto
    @crypto ||= Acme::Crypto.new(private_key)
  end
end
