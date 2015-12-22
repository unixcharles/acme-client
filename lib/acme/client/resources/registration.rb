class Acme::Client::Resources::Registration
  attr_reader :id, :key, :contact, :uri, :next_uri, :recover_uri, :term_of_service_uri

  def initialize(client, response)
    @client = client
    @uri = response.headers['location']
    assign_links(response.headers['Link'])
    assign_attributes(response.body)
  end

  def get_terms
    return unless @term_of_service_uri

    @client.connection.get(@term_of_service_uri).body
  end

  def agree_terms
    return true unless @term_of_service_uri

    response = @client.connection.post(@uri, resource: 'reg', agreement: @term_of_service_uri)
    response.success?
  end

  private

  def assign_links(links)
    @next_uri = links['next']
    @recover_uri = links['recover']
    @term_of_service_uri = links['terms-of-service']
  end

  def assign_attributes(body)
    @id = body['id']
    @key = body['key']
    @contact = body['contact']
  end
end
