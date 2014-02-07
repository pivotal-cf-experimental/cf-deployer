require "dogapi"

require "cf_deployer/hooks/datadog_emitter"
require "cf_deployer/hooks/token_installer"

module CfDeployer
  class CfDeploy
    def initialize(env, logger)
      @env = env
      @logger = logger
    end

    def create_final_release_and_deploy!
      install_deployment_hooks(@env.strategy, @env.deployment, @env.manifest_generator)

      @env.strategy.deploy!

      promote_branch(@env.strategy)
    end

    private
    attr_reader :env

    def install_deployment_hooks(strategy, deployment, manifest_generator)
      install_datadog_hook(strategy, deployment.bosh_environment)

      install_token_hook(strategy, manifest_generator)
    end

    def promote_branch(strategy)
      return unless env.options.promote_branch
      strategy.promote_to!(env.options.promote_branch)
    end

    def install_token_hook(strategy, manifest_generator)
      return unless env.options.install_tokens
      strategy.install_hook TokenInstaller.new(manifest_generator, env.runner)
    end

    def install_datadog_hook(strategy, env)
      if env["DATADOG_API_KEY"]
        dogapi = Dogapi::Client.new(
          env["DATADOG_API_KEY"],
          env["DATADOG_APPLICATION_KEY"])

        strategy.install_hook(
          DatadogEmitter.new(@logger, dogapi, @env.options.deployment_name))
      end
    end
  end
end
