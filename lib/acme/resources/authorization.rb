class Acme::Resources::Authorization
  HTTP01 = Acme::Resources::Challenges::HTTP01

  attr_reader :domain, :status, :http01

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
