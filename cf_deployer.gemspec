$:.push File.expand_path("../lib", __FILE__)
require 'cf_deployer/version'

Gem::Specification.new do |s|
  s.name        = "cf_deployer"
  s.version     = CfDeployer::VERSION
  s.authors     = ["Cloud Foundry Team"]
  s.email       = %w(cf-eng@pivotallabs.com)
  s.homepage    = "http://github.com/cloudfoundry/cf-deployer"
  s.summary     = %q{
    Friendly command-line interface for Cloud Foundry deploys.
  }
  s.executables = %w{cf_deploy promote}

  s.files         = %w(LICENSE) + Dir["lib/**/*"]
  s.license       = "Apache 2.0"
  s.test_files    = Dir["spec/**/*"]
  s.require_paths = %w(lib)

  s.add_runtime_dependency "dogapi", "~> 1.9"
  s.add_runtime_dependency "bosh_cli", "~> 1.5.0.pre.3"
  s.add_runtime_dependency "cf", "~> 5.2.2"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "blue-shell"
  s.add_development_dependency "timecop"
end
