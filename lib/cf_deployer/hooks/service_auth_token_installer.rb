require "cf_deployer/hooks/hook"

module CfDeployer
  class ServiceAuthTokenInstaller < Hook
    def initialize(logger, manifest)
      @logger = logger
      @manifest = manifest
    end

    def post_deploy
      client = CFoundry::Client.get(@manifest.api_endpoint)

      user, pass = @manifest.admin_credentials
      client.login(username: user, password: pass)

      services = @manifest.appdirect_services
      unless services
        @logger.log_message "no services; skipping token installation"
        return
      end

      @manifest.appdirect_services.each do |svc|
        label = svc[:label]
        provider = svc[:provider]

        @logger.log_message "installing service auth token for '#{label}' (via '#{provider}')"

        token = client.service_auth_token
        token.label = label
        token.provider = provider
        token.token = svc[:token]

        begin
          token.create!
        rescue CFoundry::ServiceAuthTokenLabelTaken
          @logger.log_message "service auth token already installed"
        end
      end
    end
  end
end
