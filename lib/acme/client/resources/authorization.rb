class Acme::Client::Resources::Authorization
  HTTP01 = Acme::Client::Resources::Challenges::HTTP01
  DNS01 = Acme::Client::Resources::Challenges::DNS01
  TLSSNI01 = Acme::Client::Resources::Challenges::TLSSNI01

  attr_reader :client, :uri, :domain, :status, :expires, :http01, :dns01, :tls_sni01

  def initialize(client, uri, response)
    @client = client
    @uri = uri
    assign_attributes(response.body)
  end

  def verify_status
    response = @client.connection.get(@uri)

    assign_attributes(response.body)
    status
  end

  private

  def assign_attributes(body)
    @expires = Time.iso8601(body['expires']) if body.key? 'expires'
    @domain = body['identifier']['value']
    @status = body['status']
    assign_challenges(body['challenges'])
  end

  def assign_challenges(challenges)
    challenges.each do |attributes|
      challenge = case attributes.fetch('type')
                  when 'http-01'
                    @http01 ||= HTTP01.new(self)
                  when 'dns-01'
                    @dns01 ||= DNS01.new(self)
                  when 'tls-sni-01'
                    @tls_sni01 ||= TLSSNI01.new(self)
      end

      challenge.assign_attributes(attributes) if challenge
    end
  end
end
