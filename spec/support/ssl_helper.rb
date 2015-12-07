module SSLHelper
  def generate_private_key
    OpenSSL::PKey::RSA.new(2048)
  rescue OpenSSL::PKey::RSAError # Try again
    sleep(0.05)
    OpenSSL::PKey::RSA.new(2048)
  end

  def generate_csr(common_name, private_key)
    request = OpenSSL::X509::Request.new
    request.subject = OpenSSL::X509::Name.new([
      ['CN', common_name, OpenSSL::ASN1::UTF8STRING]
    ])

    request.public_key = private_key.public_key
    request.sign(private_key, OpenSSL::Digest::SHA256.new)
    request
  end
end
