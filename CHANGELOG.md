## `2.0.9`

* Support for Ruby 3.0 and Faraday 0.17.x
* Raise when directory is rate limited

## `2.0.8`

* Add support for the keyChange endpoint

https://tools.ietf.org/html/rfc8555#section-7.3.5


## `2.0.7`

* Add support for alternate certificate chain
* Change `Link` headers parsing to return array of value. This add support multiple entries at the same `rel`

## `2.0.6`

* Allow Faraday up to `< 2.0`

## `2.0.5`

* Use post-as-get
* Remove deprecated keyAuthorization

## `2.0.4`

* Add an option to retry bad nonce errors

## `2.0.3`

* Do not try to set the body on GET request

## `2.0.2`

* Fix constant lookup on InvalidDirectory
* Forward connection options when fetching nonce
* Fix splats without parenthesis warning

## `2.0.1`

* Properly require URI

## `2.0.0`

* Release of the `ACMEv2` branch

## `1.0.0`

* Development for `ACMEv1` moved into `1.0.x`

## `0.6.3`

* Handle Faraday::ConnectionFailed errors as Timeout error.

## `0.6.2`

* Do not cache error type

## `0.6.1`

* Fix typo in ECDSA curves

## `0.6.0`

* Support external account keys

## `0.5.5`

* Release script fixes.

## `0.5.4`

* Enable ECDSA certificates

## `0.5.3`

* Build release script

## `0.5.2`

* Fix acme error names
* ASN1 parsing improvements

## `0.5.1`

* Set serial number of self-signed certificate

## `0.5.0`

* Allow access to `Acme::Client#endpoint` and `Acme::Client#directory_uri`
* Add `Acme::Client#fetch_authorization`
* Setup cyclic dependency between challenges and their authorization for easier access of either with the other.
* Drop `Acme::Client#challenge_from_hash` and `Acme::Client::Resources::Challenges::Base#to_h` in favor of the new API.
* Delegate `Acme::Client::Resources::Challenges::Base#verify_status` to `Acme::Client::Resources::Authorization#verify_status` and make it update existing challenge objects. This makes it so that whichever is called, the correct status is reflected everywhere.
* Add `Authorization#verify_status` - Recent versions of boulder will no longer process a challenge if the associated authorization is already valid, that is another challenge was previously solved. This means we need to allow people to poll on the authorizations status rather than the challenge status so they don't have to poll on the status of all challenges of an authorization all the time. See https://community.letsencrypt.org/t/upcoming-change-valid-authz-reuse/16982 and https://github.com/letsencrypt/boulder/issues/2057

## `0.4.1`

* Set the X509 version of the self-signed certificate
* Fix requiring of time standard library

## `0.4.0`

* Drop json-jwt dependency, implement JWS on our own
* Drop ActiveSupport dependency

## `0.3.7`

* Simplify internal `require` statements
* Fix usage of json-jwt return value
* Remove usage of deprecated `qualified_const_defined?`
* Add user agent to upstream calls
* Fix gem requiring
* Set CSR version

## `0.3.6`

* Handle non-json errors better

## `0.3.5`

* Handle non protocol related server error

## `0.3.4`

* Make `Acme::Client#challenge_from_hash` more strict with the arguments it receives

## `0.3.3`

* Add new `unsupportedIdentifier` error from acme protocol

## `0.3.2`

* Adds `rejectedIdentifier` error
* Adds `RateLimited` error class
* Clean up gem loading
* Make client connection options configurable
* Add URL to certificate

## `0.3.1`

* Add ability to serialize challenges

## `0.3.0`

* Use ISO8601 format for time parsing
* Expose the authorization expiration timestamp. The ACME server returns an optional timestamp that signifies the expiration date of the domain authorization challenge. The time format is RFC3339 and can be parsed by Time#parse. See: https://letsencrypt.github.io/acme-spec/ Section 5.3 - expires
* Update dns-01 record content to comply with ACME spec
* Fix `SelfSignCertificate#default_not_before`

## `0.2.4`

* Support tls-sni-01

## `0.2.3`

* Support certificate revocation
* Move everything under the `Acme::Client` namespace
* Improved errors
