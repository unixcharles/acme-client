# Acme::Client
[![Build Status](https://travis-ci.org/unixcharles/acme-client.svg?branch=master)](https://travis-ci.org/unixcharles/acme-client)

`acme-client` is a client implementation of the [ACME](https://letsencrypt.github.io/acme-spec) protocol in Ruby.

You can find the server reference implementation for ACME server [here](https://github.com/letsencrypt/boulder) and also the a reference [client](https://github.com/letsencrypt/letsencrypt) in python.

ACME is part of the [Letsencrypt](https://letsencrypt.org/) project, that are working hard at encrypting all the things.

## Usage

```ruby
# We're going to need a private key.
require 'openssl'
private_key = OpenSSL::PKey::RSA.new(2048)

# We need an ACME server to talk to, see github.com/letsencrypt/boulder
endpoint = 'https://acme-v01.api.letsencrypt.org/'

# Initialize the client
require 'acme/client'
client = Acme::Client.new(private_key: private_key, endpoint: endpoint)

# If the private key is not known to the server, we need to register it for the first time.
registration = client.register(contact: 'mailto:contact@example.com')

# You'll may need to agree to the term (that's up the to the server to require it or not but boulder does by default)
registration.agree_terms

# Let's try to optain a certificate for example.org

# We need to prove that we control the domain using one of the challenges method.
authorization = client.authorize(domain: 'example.org')

# For now the only challenge method supprted by the client is http-01.
challenge = authorization.http01

# The http-01 method will require you to response to an HTTP request.

# You can retrieve the expected path for the file.
challenge.filename # => ".well-known/acme-challenge/:some_token"

# You can generate the body of the expected response.
challenge.file_content # => 'string token and JWK thumbprint'

# You can send no Content-Type at all but if you send one it has to be 'text/plain'.
challenge.content_type

# Save the file. We'll create a public directory to serve it from, and we'll creating the challenge directory.
FileUtils.mkdir_p( File.join( 'public', File.dirname( challenge.filename ) ) )

# Then writing the file
File.write( File.join( 'public', challenge.filename), challenge.file_content )

# The challenge file can be server with a Ruby webserver such as run a webserver in another console. You may need to forward ports on your router
#ruby -run -e httpd public -p 8080 --bind-address 0.0.0.0


# Once you are ready to serve the confirmation request you can proceed.
challenge.request_verification # => true
challenge.verify_status # => 'pending'

# Wait a bit for the server to make the request, or really just blink, it should be fast.
sleep(1)

challenge.verify_status # => 'valid'

# We're going to need a certificate signing request. If not explicitly
# specified, the first name listed becomes the common name.
csr = Acme::Client::CertificateRequest.new(names: %w[example.org www.example.org])

# We can now request a certificate, you can pass anything that returns
# a valid DER encoded CSR when calling to_der on it, for example a
# OpenSSL::X509::Request too.
certificate = client.new_certificate(csr) # => #<Acme::Client::Certificate ....>

# Save the certificate and key
File.write("privkey.pem", certificate.request.private_key.to_pem)
File.write("cert.pem", certificate.to_pem)
File.write("chain.pem", certificate.chain_to_pem)
File.write("fullchain.pem", certificate.fullchain_to_pem)

# Start a webserver, using your shiny new certificate
# ruby -r openssl -r webrick -r 'webrick/https' -e "s = WEBrick::HTTPServer.new(
#   :Port => 8443,
#   :DocumentRoot => Dir.pwd,
#   :SSLEnable => true,
#   :SSLPrivateKey => OpenSSL::PKey::RSA.new( File.read('privkey.pem') ),
#   :SSLCertificate => OpenSSL::X509::Certificate.new( File.read('cert.pem') )); trap('INT') { s.shutdown }; s.start"
```

# Not implemented

- Recovery methods are not implemented.
- proofOfPossession-01 is not implemented.

# Requirements

Ruby >= 2.1

## Development

All the tests use VCR to mock the interaction with the server but if you
need to record new interation against the server simply clone boulder and
run it normally with `./start.py`.

## Pull request?

Yes.

## License

[MIT License](http://opensource.org/licenses/MIT)

