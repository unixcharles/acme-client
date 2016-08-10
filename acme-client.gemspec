# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acme/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'acme-client'
  spec.version       = Acme::Client::VERSION
  spec.authors       = ['Charles Barbier']
  spec.email         = ['unixcharles@gmail.com']
  spec.summary       = 'Client for the ACME protocol.'
  spec.homepage      = 'http://github.com/unixcharles/acme-client'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1.0'

  spec.add_development_dependency 'bundler', '~> 1.6', '>= 1.6.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.3', '>= 3.3.0'
  spec.add_development_dependency 'vcr', '~> 2.9', '>= 2.9.3'
  spec.add_development_dependency 'webmock', '~> 1.21', '>= 1.21.0'

  spec.add_runtime_dependency 'faraday', '~> 0.9', '>= 0.9.1'
end
