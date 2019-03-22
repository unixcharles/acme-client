# Acme::Client

[![Build Status](https://travis-ci.org/unixcharles/acme-client.svg?branch=master)](https://travis-ci.org/unixcharles/acme-client)

`acme-client` is a client implementation of the [ACMEv2](https://github.com/ietf-wg-acme/acme) protocol in Ruby.

You can find the ACME reference implementations of the [server](https://github.com/letsencrypt/boulder) in Go and the [client](https://github.com/certbot/certbot) in Python.

ACME is part of the [Letsencrypt](https://letsencrypt.org/) project, which goal is to provide free SSL/TLS certificates with automation of the acquiring and renewal process.

You can find ACMEv1 compatible client in the [acme-v1](https://github.com/unixcharles/acme-client/tree/acme-v1) branch.

## Installation

Via RubyGems:

    $ gem install acme-client

Or add it to a Gemfile:

```ruby
gem 'acme-client'
```

## Usage
* [Setting up a client](#setting-up-a-client)
* [Account management](#account-management)
* [Obtaining a certificate](#obtaining-a-certificate)
  * [Ordering a certificate](#ordering-a-certificate)
  * [Completing an HTTP challenge](#preparing-for-http-challenge)
  * [Completing an DNS challenge](#preparing-for-dns-challenge)
  * [Requesting a challenge verification](#requesting-a-challenge-verification)
  * [Downloading a certificate](#downloading-a-certificate)
* [Extra](#extra)
  * [Certificate revokation](#certificate-revokation)
  * [Certificate renewal](#certificate-renewal)

## Setting up a client

The client is initialized with a private key and the directory of your ACME provider.

LetsEncrypt's `directory` is `https://acme-v02.api.letsencrypt.org/directory`.

They also have a staging endpoint at `https://acme-staging-v02.api.letsencrypt.org/directory`.

`acme-ruby` expects `OpenSSL::PKey::RSA` or `OpenSSL::PKey::EC`

You can generate one in Ruby using OpenSSL.

```ruby
require 'openssl'
private_key = OpenSSL::PKey::RSA.new(4096)
```

Load one from a PEM file

```ruby
require 'openssl'
private_key = OpenSSL::PKey::RSA.new(File.read('/path/to/private_key.pem'))
```
See [RSA](https://ruby.github.io/openssl/OpenSSL/PKey/RSA.html) and [EC](https://ruby.github.io/openssl/OpenSSL/PKey/EC.html) for documentation.

```ruby
client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')
```

Load a `jwk` (JSON Web Key)
This will require `JOSE` (`gem install jose`) but this makes loading your JWK much easier.

```ruby
jwk = JOSE::JWK.from(JSON.load(File.read('/path/to/private_key.json')))
```
Using the variable, you can translate the jwk to a raw key.
```ruby
client = Acme::Client.new(private_key: jwk.to_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')
```

Passing your Key ID

If your account is already registered, you can save some API calls by passing your key ID directly. This will avoid an unnecessary API call to retrieve it from your private key.

<!-- Indented for readability and not having to scroll -->
```ruby
client = Acme::Client.new(
    private_key: private_key,
    directory: 'https://acme-staging-v02.api.letsencrypt.org/directory',
    kid: 'https://example.com/acme/acct/1'
)
```

## Account management

Accounts are tied to a private key. Before being allowed to create orders, the account must be registered and the ToS accepted using the private key. The account will be assigned a key ID.

```ruby
client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')
account = client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
```

After the registration you can retrieve the account  key indentifier (kid).

```ruby
client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')
account = client.new_account(contact: 'mailto:info@example.com', terms_of_service_agreed: true)
account.kid # => <kid string>
```

If you already have an existing account (for example one created in ACME v1) please note that unless the `kid` is provided at initialization, the client will lazy load the `kid` by doing a `POST` to `newAccount` whenever the `kid` is required. Therefore, you can easily get your `kid` for an existing account and (if needed) store it for reuse:

```
client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')

# kid is not set, therefore a call to newAccount is made to lazy-initialize the kid
client.kid
=> "https://acme-staging-v02.api.letsencrypt.org/acme/acct/000000"
```

## Obtaining a certificate
### Ordering a certificate

To order a new certificate, the client must provide a list of identifiers.

The returned order will contain a list of `Authorization` that need to be completed in other to finalize the order, generally one per identifier.

Each authorization contains multiple challenges, typically a `dns-01` and a `http-01` challenge. The applicant is only required to complete one of the challenges.

You can access the challenge you wish to complete using the `#dns` or `#http` method.

```ruby
order = client.new_order(identifiers: ['example.com'])
authorization = order.authorizations.first
challenge = authorization.http
```

### Preparing for HTTP challenge

To complete the HTTP challenge, you must return a file using HTTP.

The path follows the following format:

> .well-known/acme-challenge/#{token}

And the file content is the key authorization. The HTTP01 object has utility methods to generate them.

```ruby
> http_challenge.content_type # => 'text/plain'
> http_challenge.file_content # => example_token.TO1xJ0UDgfQ8WY5zT3txynup87UU3PhcDEIcuPyw4QU
> http_challenge.filename # => '.well-known/acme-challenge/example_token'
> http_challenge.token # => 'example_token'
```

For test purposes you can just save the challenge file and use Ruby to serve it:

```bash
ruby -run -e httpd public -p 8080 --bind-address 0.0.0.0
```

### Preparing for DNS challenge

To complete the DNS challenge, you must set a DNS record to prove that you control the domain.

The DNS01 object has utility methods to generate them.

```ruby
dns_challenge.record_name # => '_acme-challenge'
dns_challenge.record_type # => 'TXT'
dns_challenge.record_content # => 'HRV3PS5sRDyV-ous4HJk4z24s5JjmUTjcCaUjFt28-8'
```

### Requesting a challenge verification

Once you are ready to complete the challenge, you can request the server perform the verification.

```ruby
challenge.request_validation
```

The validation is performed asynchronously and can take some time to be performed by the server.

You can poll until its status changes.

```ruby
while challenge.status == 'pending'
  sleep(2)
  challenge.reload
end
challenge.status # => 'valid'
```

### Downloading a certificate

Once all required authorizations have been validated through challenges, the order can be finalized using a CSR ([Certificate Signing Request](https://en.wikipedia.org/wiki/Certificate_signing_request)).

A CSR can be slightly tricky to generate using OpenSSL from Ruby standard library. `acme-client` provide a utility class `CertificateRequest` to help with that. You'll need to use a different private key for the certificate request than the one you use for your `Acme::Client` account.

Certificate generation happens asynchronously. You may need to poll.

```ruby
csr = Acme::Client::CertificateRequest.new(private_key: a_different_private_key, subject: { common_name: 'example.com' })
order.finalize(csr: csr)
sleep(1) while order.status == 'processing'
order.certificate # => PEM-formatted certificate
```

## Extra

### Certificate revokation

To revoke a certificate you can call `#revoke` with the certificate.

```ruby
client.revoke(certificate: certificate)
```

### Certificate renewal

The is no renewal process, just create a new order.


## Not implemented

- Account Key Roll-over.

## Requirements

Ruby >= 2.1

## Development

All the tests use VCR to mock the interaction with the server. If you need to record new interaction you can specify the directory URL with the `ACME_DIRECTORY_URL` environment variable.

```
ACME_DIRECTORY_URL=https://acme-staging-v02.api.letsencrypt.org/directory rspec
```

## Pull request?

Yes.

## License

[MIT License](http://opensource.org/licenses/MIT)

