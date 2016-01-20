class Acme::Client::Resources::Authorization
  HTTP01 = Acme::Client::Resources::Challenges::HTTP01
  DNS01 = Acme::Client::Resources::Challenges::DNS01
  TLSSNI01 = Acme::Client::Resources::Challenges::TLSSNI01

  attr_reader :domain, :status, :expires, :http01, :dns01, :tls_sni01

  def initialize(client, response)
    @client = client
    assign_challenges(response.body['challenges'])
    assign_attributes(response.body)
  end

  private

  def assign_challenges(challenges)
    challenges.each do |attributes|
      case attributes.fetch('type')
      when 'http-01' then @http01 = HTTP01.new(@client, attributes)
      when 'dns-01' then @dns01 = DNS01.new(@client, attributes)
      when 'tls-sni-01' then @tls_sni01 = TLSSNI01.new(@client, attributes)
        # else no-op
      end
    end
  end

  def assign_attributes(body)
    @expires = Time.parse(body['expires']) if body.has_key? 'expires'
    @domain = body['identifier']['value']
    @status = body['status']
  end
end
