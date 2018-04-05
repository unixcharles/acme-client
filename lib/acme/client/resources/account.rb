# frozen_string_literal: true

class Acme::Client::Resources::Account
  attr_reader :url, :status, :contact, :term_of_service, :orders_url

  def self.arguments_from_response(response)
    attributes = response.body
    status = attributes.fetch('status')
    term_of_service = attributes['termsOfServiceAgreed']
    contact = attributes.fetch('contact', [])

    { term_of_service: term_of_service, status: status, contact: contact }
  end

  def initialize(client, **arguments)
    @client = client
    assign_attributes(arguments)
  end

  def kid
    url
  end

  def update(contact: nil, terms_of_service_agreed: nil)
    assign_attributes **@client.account_update(
      contact: contact, terms_of_service_agreed: term_of_service
    ).to_h
    true
  end

  def deactivate
    assign_attributes **@client.account_deactivate.to_h
    true
  end

  def reload
    assign_attributes **@client.account.to_h
    true
  end

  def to_h
    {
      url: url,
      term_of_service: term_of_service,
      status: status,
      contact: contact
    }
  end

  private

  def assign_attributes(url:, term_of_service:, status:, contact:)
    @url = url
    @term_of_service = term_of_service
    @status = status
    @contact = contact
  end
end
