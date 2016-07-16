# This file lives here for backward compatibility only and should be deprecated soon
# gem named acme-client should be required as
# require 'acme/client'

require 'faraday'
require 'json'
require 'json/jwt'
require 'openssl'
require 'digest'
require 'forwardable'

module Acme; end

require 'acme/client'
require 'acme/client/version'
require 'acme/client/certificate'
require 'acme/client/certificate_request'
require 'acme/client/self_sign_certificate'
require 'acme/client/crypto'
require 'acme/client/resources'
require 'acme/client/faraday_middleware'
require 'acme/client/error'
