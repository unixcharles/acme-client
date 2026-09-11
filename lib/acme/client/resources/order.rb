# frozen_string_literal: true

class Acme::Client::Resources::Order
  attr_reader :url, :status, :contact, :finalize_url, :identifiers, :authorization_urls, :expires, :certificate_url, :profile, :replaces, :error, :retry_after, :retry_after_time

  def initialize(client, **arguments)
    @client = client
    assign_attributes(**arguments)
  end

  def reload
    raise Acme::Client::Error::OrderUrlNil, 'Cannot reload order with nil url.' if url.nil?

    assign_attributes(**@client.order(url: url).to_h)
    true
  end

  def authorizations
    @authorization_urls.map do |authorization_url|
      @client.authorization(url: authorization_url)
    end
  end

  def finalize(csr:)
    assign_attributes(**@client.finalize(url: finalize_url, csr: csr).to_h)
    true
  end

  def certificate(force_chain: nil)
    if certificate_url
      @client.certificate(url: certificate_url, force_chain: force_chain)
    else
      raise Acme::Client::Error::CertificateNotReady, 'No certificate_url to collect the order'
    end
  end

  def renew(replaces: nil, **arguments)
    replaces ||= renewal_info.ari_id

    @client.new_order(replaces: replaces, **to_h.slice(:identifiers, :profile).merge(arguments))
  end

  def renewal_info(certificate: nil, ari_id: nil)
    certificate ||= self.certificate if ari_id.nil?

    @client.renewal_info(certificate:, ari_id:)
  end

  def typed_error
    return nil unless error

    problem = Acme::Client::Problem.from(error)
    error_type = problem&.type
    error_detail = problem&.detail || 'Unknown error'
    error_class = Acme::Client::Error::ACME_ERRORS.fetch(error_type, Acme::Client::Error)
    error_class.new(error_detail, problem: problem)
  end

  def to_h
    {
      url: url,
      status: status,
      expires: expires,
      finalize_url: finalize_url,
      authorization_urls: authorization_urls,
      identifiers: identifiers,
      certificate_url: certificate_url,
      profile: profile,
      replaces: replaces,
      error: error,
      retry_after: retry_after
    }
  end

  private

  def assign_attributes(url: nil, status:, expires:, finalize_url:, authorization_urls:, identifiers:, certificate_url: nil, profile: nil, replaces: nil, error: nil, retry_after: nil) # rubocop:disable Layout/LineLength,Metrics/ParameterLists
    @url = url unless url.nil?
    @status = status
    @expires = expires
    @finalize_url = finalize_url
    @authorization_urls = authorization_urls
    @identifiers = identifiers
    @certificate_url = certificate_url
    @profile = profile
    @replaces = replaces
    @error = error
    @retry_after = retry_after
    @retry_after_time = Acme::Client::Util.parse_retry_after(retry_after)
  end
end
