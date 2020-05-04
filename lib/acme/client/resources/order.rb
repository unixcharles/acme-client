# frozen_string_literal: true

class Acme::Client::Resources::Order
  attr_reader :url, :status, :contact, :finalize_url, :identifiers, :authorization_urls, :expires, :certificate_url

  def initialize(client, **arguments)
    @client = client
    assign_attributes(**arguments)
  end

  def reload
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

  def certificate
    if certificate_url
      @client.certificate(url: certificate_url)
    else
      raise Acme::Client::Error::CertificateNotReady, 'No certificate_url to collect the order'
    end
  end

  def to_h
    {
      url: url,
      status: status,
      expires: expires,
      finalize_url: finalize_url,
      authorization_urls: authorization_urls,
      identifiers: identifiers,
      certificate_url: certificate_url
    }
  end

  private

  def assign_attributes(url:, status:, expires:, finalize_url:, authorization_urls:, identifiers:, certificate_url: nil)
    @url = url
    @status = status
    @expires = expires
    @finalize_url = finalize_url
    @authorization_urls = authorization_urls
    @identifiers = identifiers
    @certificate_url = certificate_url
  end
end
