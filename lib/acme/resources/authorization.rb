class Acme::Resources::Authorization
  HTTP01 = Acme::Resources::Challenges::HTTP01
  DNS01 = Acme::Resources::Challenges::DNS01
  TLSSNI01 = Acme::Resources::Challenges::TLSSNI01

  attr_reader :domain, :status, :http01, :dns01, :tlssni01

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
      when 'tls-sni-01' then @tlssni01 = TLSSNI01.new(@client, attributes)
      else
        # no supported
      end
    end
  end

  def assign_attributes(body)
    @domain = body['identifier']['value']
    @status = body['status']
  end
end
