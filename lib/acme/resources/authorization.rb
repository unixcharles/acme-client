class Acme::Resources::Authorization
  SimpleHttp = Acme::Resources::Challenges::SimpleHttp
  HTTP01 = Acme::Resources::Challenges::HTTP01

  attr_reader :domain, :status, :simple_http, :http01

  def initialize(client, response)
    @client = client
    assign_challenges(response.body['challenges'])
    assign_attributes(response.body)
  end

  private

  def assign_challenges(challenges)
    challenges.each do |attributes|
      case attributes.fetch('type')
      when 'simpleHttp' then @simple_http = SimpleHttp.new(@client, attributes)
      when 'http-01' then @http01 = HTTP01.new(@client, attributes)
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
