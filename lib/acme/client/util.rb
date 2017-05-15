module Acme::Client::Util
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

  # Verify a CSR's signature.
  #
  # csr  - A OpenSSL::X509::Request instance.
  # priv - An OpenSSL::PKey::EC or OpenSSL::PKey::RSA instance.
  #
  # Returns boolean.
  def verify_csr(csr, priv)
    case priv
    when OpenSSL::PKey::EC
      csr.verify(priv)
    when OpenSSL::PKey::RSA
      csr.verify(priv.public_key)
    else
      raise ArgumentError, 'priv must be EC or RSA'
    end
  end

  # Export a private key's public key in DER format.
  #
  # priv - An OpenSSL::PKey::EC or OpenSSL::PKey::RSA instance.
  #
  # Returns a String.
  def public_key_to_der(priv)
    case priv
    when OpenSSL::PKey::EC
      dup = OpenSSL::PKey::EC.new(priv.to_der)
      dup.private_key = nil
      dup.to_der
    when OpenSSL::PKey::RSA
      priv.public_key.to_der
    else
      raise ArgumentError, 'priv must be EC or RSA'
    end
  end

  extend self
end
