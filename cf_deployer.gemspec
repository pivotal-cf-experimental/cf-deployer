$:.push File.expand_path("../lib", __FILE__)
require "cf/version"

Gem::Specification.new do |s|
  s.name        = "cf_deployer"
  s.version     = CF::VERSION.dup
  s.authors     = ["Cloud Foundry Team"]
  s.email       = %w(cf-eng@pivotallabs.com)
  s.homepage    = "http://github.com/cloudfoundry/cf-deployer"
  s.summary     = %q{
    Friendly command-line interface for Cloud Foundry deploys.
  }
  s.executables = %w{cf_deploy}

  s.files         = %w(LICENSE) + Dir["lib/**/*"]
  s.license       = "Apache 2.0"
  s.test_files    = Dir["spec/**/*"]
  s.require_paths = %w(lib)

  s.add_runtime_dependency "dogapi", "~> 1.9"
end
