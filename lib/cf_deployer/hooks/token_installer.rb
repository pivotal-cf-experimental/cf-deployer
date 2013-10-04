require "cf_deployer/hooks/hook"

module CfDeployer
  class TokenInstaller < Hook
    def initialize(logger, manifest, runner)
      @logger = logger
      @manifest = manifest
      @runner = runner
    end

    def post_deploy
      username, password = @manifest.admin_credentials
      @runner.run!("cf target #{@manifest.api_endpoint}")
      @runner.run!("cf login --username #{username} --password #{password} --organization pivotal")
      @manifest.appdirect_tokens.each do |service|
        @runner.run!("cf create-service-auth-token #{service['name']} #{service['provider']} --token #{service['auth_token']} 2>/dev/null || true")
      end
    end
  end
end
