require "dogapi"

require "cf_deployer/hooks/datadog_emitter"
require "cf_deployer/hooks/token_installer"

module CfDeployer
  class CfDeploy
    def self.build(options)
      deploy_env = CfDeployer::DeployEnvironment.new(options)
      deploy_env.prepare
      new(deploy_env)
    end

    def initialize(env, logger = env.logger)
      @env = env
      @logger = logger

      install_deployment_hooks(env.strategy, env.deployment, env.manifest_generator)
    end

    def create_release
      env.strategy.create_release
    end

    def upload_release
      env.strategy.upload_release
    end

    def deploy_release
      env.strategy.deploy_release
    end

    def promote_release
      return unless env.options.promote_branch

      env.strategy.promote_release(env.options.promote_branch)
    end

    private

    attr_reader :env

    def install_deployment_hooks(strategy, deployment, manifest_generator)
      install_datadog_hook(strategy, deployment.bosh_environment)
      install_token_hook(strategy, manifest_generator)
    end

    def install_token_hook(strategy, manifest_generator)
      return unless env.options.install_tokens

      strategy.install_hook TokenInstaller.new(manifest_generator, env.runner)
    end

    def install_datadog_hook(strategy, bosh_environment)
      return unless bosh_environment.has_key?("DATADOG_API_KEY")

      dogapi = Dogapi::Client.new(bosh_environment["DATADOG_API_KEY"], bosh_environment["DATADOG_APPLICATION_KEY"])
      strategy.install_hook(DatadogEmitter.new(@logger, dogapi, env.options.deployment_name))
    end
  end
end
