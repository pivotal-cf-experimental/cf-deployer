require 'dogapi'

require 'cf_deployer/deploy_environment'
require 'cf_deployer/hooks/datadog_emitter'
require 'cf_deployer/hooks/token_installer'
require 'cf_deployer/logger'

module CfDeployer
  class CfDeploy
    def self.build(options, logger = CfDeployer::Logger.new)
      new(CfDeployer::DeployEnvironment.new(options, logger), logger)
    end

    def initialize(deploy_environment, logger)
      @deploy_environment = deploy_environment
      @logger = logger

      install_deployment_hooks(deploy_environment.strategy, deploy_environment.deployment, deploy_environment.manifest_generator)
    end

    def create_release
      deploy_environment.strategy.create_release
    end

    def upload_release
      deploy_environment.strategy.upload_release
    end

    def deploy_release
      deploy_environment.strategy.deploy_release
    end

    def tag_and_push_final_release
      deploy_environment.strategy.tag_and_push_final_release(deploy_environment.options.push_branch)
    end

    def promote_release
      return unless deploy_environment.options.promote_branch

      deploy_environment.strategy.promote_release(deploy_environment.options.promote_branch)
    end

    private

    attr_reader :deploy_environment

    def install_deployment_hooks(strategy, deployment, manifest_generator)
      install_datadog_hook(strategy, deployment.bosh_environment)
      install_token_hook(strategy, manifest_generator)
    end

    def install_token_hook(strategy, manifest_generator)
      return unless deploy_environment.options.install_tokens

      strategy.install_hook TokenInstaller.new(manifest_generator, deploy_environment.runner)
    end

    def install_datadog_hook(strategy, bosh_environment)
      return unless bosh_environment.has_key?('DATADOG_API_KEY')

      dogapi = Dogapi::Client.new(bosh_environment['DATADOG_API_KEY'], bosh_environment['DATADOG_APPLICATION_KEY'])
      strategy.install_hook(DatadogEmitter.new(@logger, dogapi, deploy_environment.options.deployment_name))
    end
  end
end
