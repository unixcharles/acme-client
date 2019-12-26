module Acme::Client::Util
  extend self

  def urlsafe_base64(data)
    Base64.urlsafe_encode64(data).sub(/[\s=]*\z/, '')
  end

  # Sets public key on CSR or cert.
  #
  # obj  - An OpenSSL::X509::Certificate or OpenSSL::X509::Request instance.
  # priv - An OpenSSL::PKey::EC or OpenSSL::PKey::RSA instance.
  #
  # Returns nothing.
  def set_public_key(obj, priv)
    case priv
    when OpenSSL::PKey::EC
      obj.public_key = priv
    when OpenSSL::PKey::RSA
      obj.public_key = priv.public_key
    else
      raise ArgumentError, 'priv must be EC or RSA'
    end
  end
end
