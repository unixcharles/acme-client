# frozen_string_literal: true

class Acme::Client::Resources::Account
  attr_reader :status, :contact, :term_of_service, :orders_url

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

  def reload
    assign_attributes **@client.authorization(location: url).to_h
    true
  end

  def to_h
    {
      term_of_service: term_of_service,
      status: status,
      contact: contact
    }
  end

  private

  def assign_attributes(term_of_service:, status:, contact:)
    @term_of_service = term_of_service
    @status = status
    @contact = contact
  end
end
