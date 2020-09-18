# frozen_string_literal: true

class Acme::Client::FaradayMiddleware < Faraday::Middleware
  attr_reader :env, :response, :client

  CONTENT_TYPE = 'application/jose+json'

  def initialize(app, client:, mode:)
    super(app)
    @client = client
    @mode = mode
  end

  def call(env)
    @env = env
    @env[:request_headers]['User-Agent'] = Acme::Client::USER_AGENT
    @env[:request_headers]['Content-Type'] = CONTENT_TYPE

    if @env.method != :get
      @env.body = client.jwk.jws(header: jws_header, payload: env.body)
    end

    @app.call(env).on_complete { |response_env| on_complete(response_env) }
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
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

  def jws_header
    headers = { nonce: pop_nonce, url: env.url.to_s }
    headers[:kid] = client.kid if @mode == :kid
    headers
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
    Acme::Client::Error::ACME_ERRORS.fetch(error_name, Acme::Client::Error)
  end

  def error_name
    return unless env.body.is_a?(Hash)
    return unless env.body.key?('type')
    env.body['type']
  end

  def decode_body
    content_type = env.response_headers['Content-Type'].to_s

    if content_type.start_with?('application/json', 'application/problem+json')
      JSON.load(env.body)
    else
      env.body
    end
  end

  def decode_link_headers
    return unless env.response_headers.key?('Link')
    link_header = env.response_headers['Link']
    Acme::Client::Util.decode_link_headers(link_header)
  end

  def store_nonce
    nonce = env.response_headers['replay-nonce']
    nonces << nonce if nonce
  end

  def pop_nonce
    if nonces.empty?
      get_nonce
    end

    nonces.pop
  end

  def get_nonce
    client.get_nonce
  end

  def nonces
    client.nonces
  end
end
