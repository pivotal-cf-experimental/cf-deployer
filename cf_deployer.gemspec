$:.push File.expand_path('../lib', __FILE__)
require 'cf_deployer/version'

Gem::Specification.new do |spec|
  spec.name        = 'cf_deployer'
  spec.version     = CfDeployer::VERSION
  spec.authors     = ['Cloud Foundry Team']
  spec.email       = %w(cf-eng@pivotallabs.com)
  spec.homepage    = 'http://github.com/pivotal-cf-experimental/cf-deployer'
  spec.summary     = %q{
    Friendly command-line interface for Cloud Foundry deploys.
  }

  spec.files         = %w(LICENSE README.md) + Dir['lib/**/*']

  spec.executables   = Dir['bin/*'].map { |f| File.basename(f) }

  spec.license       = 'Apache 2.0'
  spec.test_files    = Dir['spec/**/*']
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'dogapi', '~> 1.9'
  spec.add_runtime_dependency 'bosh_cli', '~> 1.0'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.0'
  spec.add_development_dependency 'blue-shell'
  spec.add_development_dependency 'timecop'
end
