class Acme::Resources::Challenges::DVSNI01 < Acme::Resources::Challenges::Base

  def sni_name
    hd = crypto.digest.hexdigest(authorization_key)
    "#{hd[0..31]}.#{hd[32..64]}.acme.invalid"
  end

  def request_verification
    response = client.connection.post(@uri, { resource: 'challenge', type: 'dvsni-01', keyAuthorization: authorization_key })
    response.success?
  end
end
