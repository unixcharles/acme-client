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

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) || f.start_with?('.') }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'vcr', '~> 2.9'
  spec.add_development_dependency 'webmock', '~> 3.8'
  spec.add_development_dependency 'webrick', '~> 1.7'

  spec.add_runtime_dependency 'base64', '~> 0.2'
  spec.add_runtime_dependency 'faraday', '>= 1.0', '< 3.0.0'
  spec.add_runtime_dependency 'faraday-retry', '>= 1.0', '< 3.0.0'
end
