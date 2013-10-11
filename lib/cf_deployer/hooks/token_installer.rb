require "cf_deployer/hooks/hook"

module CfDeployer
  class TokenInstaller < Hook
    def initialize(logger, manifest_generator, runner)
      @logger = logger
      @manifest_generator = manifest_generator
      @runner = runner
    end

    def post_deploy
      manifest = @manifest_generator.get_manifest

      username, password = manifest.admin_credentials
      @runner.run!("cf target #{manifest.api_endpoint}")
      @runner.run!("cf login --username #{username} --password #{password} --organization pivotal")
      manifest.service_tokens.each do |service|
        @runner.run!("cf create-service-auth-token #{service['name']} #{service['provider']} --token #{service['auth_token']} 2>/dev/null || true")
      end
    end
  end
end
