module Acme::Client::Util
  extend self

  def urlsafe_base64(data)
    Base64.urlsafe_encode64(data).sub(/[\s=]*\z/, '')
  end

  LINK_MATCH = /<(.*?)>\s?;\s?rel="([\w-]+)"/

  # See RFC 8288 - https://tools.ietf.org/html/rfc8288#section-3
  def decode_link_headers(link_header)
    link_header.split(',').each_with_object({}) { |entry, hash|
      _, link, name = *entry.match(LINK_MATCH)
      hash[name] ||= []
      hash[name].push(link)
    }
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

  # Generates a certificate identifier for ACME Renewal Information (ARI) as per RFC 9773.
  # The identifier is constructed by extracting the Authority Key Identifier (AKI) from
  # the certificate extension, and the DER-encoded serial number (without tag and length bytes).
  # Both values are base64url-encoded and concatenated with a period separator.
  #
  # certificate - An OpenSSL::X509::Certificate instance or PEM string.
  #
  # Returns a string in the format: base64url(AKI).base64url(serial)
  def ari_certificate_identifier(certificate)
    cert = if certificate.is_a?(OpenSSL::X509::Certificate)
      certificate
    else
      OpenSSL::X509::Certificate.new(certificate)
    end

    aki_ext = cert.extensions.find { |ext| ext.oid == 'authorityKeyIdentifier' }
    raise ArgumentError, 'Certificate does not have an Authority Key Identifier extension' unless aki_ext

    aki_value = aki_ext.value
    hex_string = if aki_value =~ /keyid:([0-9A-Fa-f:]+)/
      $1
    elsif aki_value =~ /^[0-9A-Fa-f:]+$/
      aki_value
    else
      raise ArgumentError, 'Could not parse Authority Key Identifier'
    end

    key_identifier = hex_string.split(':').map { |hex| hex.to_i(16).chr }.join
    serial_der = OpenSSL::ASN1::Integer.new(cert.serial).to_der
    serial_value = OpenSSL::ASN1.decode(serial_der).value.to_s(2)

    aki_b64 = urlsafe_base64(key_identifier)
    serial_b64 = urlsafe_base64(serial_value)

    "#{aki_b64}.#{serial_b64}"
  end
end
