require File.expand_path('../lib/client/version', __FILE__)

Gem::Specification.new do |spec| 
  spec.name        = 'dtk-network-client'
  spec.version     = DTK::Network::Client::VERSION
  spec.author      = 'Reactor8'
  spec.email       = 'support@reactor8.com'
  spec.description = %q{Library for interaction with dtk network.}
  spec.summary     = %q{Library for interaction with dtk network.}
  spec.license     = 'Apache 2.0'
  spec.platform    = Gem::Platform::RUBY
  spec.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  spec.require_paths = ['lib']
  spec.files =  `git ls-files`.split("\n")

  spec.add_dependency 'git', '1.2.9'
  # spec.add_dependency 'dtk-common-core', '0.11.0'
  spec.add_dependency 'semverly', '~> 1.0'
  spec.add_dependency 'rest-client', '1.6.7'
  spec.add_dependency 'aws-sdk', '~> 3'
  spec.add_dependency 'dtk-dsl', '~> 1.1.0'
  spec.add_dependency 'dtk-common-core', '0.11.1'
end
