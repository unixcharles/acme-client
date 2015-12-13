class Acme::Client::Resources::Challenges::TLSSNI01 < Acme::Resources::Challenges::Base
  def hostname
    hd = crypto.digest.hexdigest(authorization_key)
    "#{hd[0..31]}.#{hd[32..64]}.acme.invalid"
  end

  def temporary_cert
    @temporary_cert ||= ::Acme::Certificate.new(nil, nil, nil).create_self_signed_cert([domain])
  end

  def self_signed_certificate
    self.temporary_cert.to_pem
  end

  def self_signed_certificate_key
    self.temporary_cert.private_key.to_pem
  end

  def request_verification
    response = client.connection.post(@uri, { resource: 'challenge', type: 'tls-sni-01', keyAuthorization: authorization_key })
    response.success?
  end
end
