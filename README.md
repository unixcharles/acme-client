# Acme::Client

`acme-client` is a client implementation of the [ACME](https://letsencrypt.github.io/acme-spec) protocol in Ruby.

You can find the server reference implementation for ACME server [here](https://github.com/letsencrypt/boulder) and also the a reference [client](https://github.com/letsencrypt/letsencrypt) in python.

ACME is part of the [Letsencrypt](https://letsencrypt.org/) project, that are working hard at encrypting all the things.

## Usage

```ruby
# We're going to need a private key.
require 'openssl'
private_key = OpenSSL::PKey::RSA.new(2048)

# We need an ACME server to talk to, see github.com/letsencrypt/boulder
endpoint = 'https://acme-staging.api.letsencrypt.org'

# Initialize the client
require 'acme-client'
client = Acme::Client.new(private_key: private_key, endpoint: endpoint)

# If the private key is not known to the server, we need to register it for the first time.
registration = client.register(contact: 'mailto:unixcharles@gmail.com')

# You'll may need to agree to the term (that's up the to the server to require it or not but boulder does by default)
registration.agree_terms

# Let's try to optain a certificate for yourdomain.com

# We need to prove that we control the domain using one of the challenges method.
authorization = client.authorize(domain: 'yourdomain.com')

# For now the only challenge method supprted by the client is http-01.
challenge = authorization.http01

# The http-01 method will require you to response to an HTTP request.

# You can retrieve the expected path for the file.
http.filename # => ".well-known/acme-challenge/:some_token"

# You can generate the body of the expected response.
http.file_content # => 'string token and JWK thumbprint' 

# You can send no Content-Type at all but if you send one it has to be 'text/plain'.
http.content_type

# Once you are ready to serve the confirmation request you can proceed.
http.request_verification # => true
http.verify_status # => 'pending'

# Wait a bit for the server to make the request, or really just blink, it should be fast.
sleep(1)

http.verify_status # => 'valid'

# We're going to need a CSR, lets do this real quick with Ruby+OpenSSL.
csr = OpenSSL::X509::Request.new

# We need a private key for the certificate, not the same as the account key.
certificate_private_key = OpenSSL::PKey::RSA.new(2048)

# We just going to add the domain but normally you might want to provide more information.
csr.subject = OpenSSL::X509::Name.new([
  ['CN', common_name, OpenSSL::ASN1::UTF8STRING]
])

csr.public_key = certificate_private_key.public_key
csr.sign(certificate_private_key, OpenSSL::Digest::SHA256.new)

# We can now request a certificate
client.new_certificate(csr) # => #<OpenSSL::X509::Certificate ....>
```

# Not implemented

- Recovery methods are not implemented.
- http-01 is the only challenge method implemented

## Development

All the tests use VCR to mock the interaction with the server but if you
need to record new interation against the server simply clone boulder and
run it normally with `./start.py`.

## Pull request?

Yes.

## License

[MIT License](http://opensource.org/licenses/MIT)

