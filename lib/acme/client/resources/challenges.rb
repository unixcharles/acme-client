module Acme::Client::Resources::Challenges; end

require 'acme/client/resources/challenges/base'
require 'acme/client/resources/challenges/http01'
require 'acme/client/resources/challenges/dns01'
require 'acme/client/resources/challenges/tls_sni01'
