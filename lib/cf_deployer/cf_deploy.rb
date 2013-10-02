require "dogapi"

require 'cf_deployer/cli'
require 'cf_deployer/release_repo'
require 'cf_deployer/deployment'
require 'cf_deployer/bosh'
require 'cf_deployer/manifest'
require 'cf_deployer/dev_deployment_strategy'
require 'cf_deployer/final_deployment_strategy'
require 'cf_deployer/hooks/datadog_emitter'

module CfDeployer
  class CfDeploy
    def initialize(options)
      @options = options
    end

    def deploy(logger, runner)
      deployments_repo = Repo.new(
        logger, runner, @options.repos_path, @options.deployments_repo,
        "master")

      deployments_repo.sync!

      release_repo = ReleaseRepo.new(
        logger, runner, @options.repos_path, @options.release_repo,
        @options.release_ref)

      release_repo.sync!

      deployment = Deployment.new(
        File.join(deployments_repo.path, @options.deployment_name))

      bosh = Bosh.new(
        logger, runner, deployment.bosh_environment,
        interactive: @options.interactive)

      manifest =
        ReleaseManifest.new(
          runner, release_repo, @options.infrastructure, "new_deployment.yml")

      strategy_type =
        if @options.final_release
          FinalDeploymentStrategy
        else
          DevDeploymentStrategy
        end

      strategy = strategy_type.new(
        bosh, deployment, release_repo, manifest, @options.release_name)

      # TODO: this is a bit dirty
      env = deployment.bosh_environment

      if env["DATADOG_API_KEY"]
        dogapi = Dogapi::Client.new(
          env["DATADOG_API_KEY"],
          env["DATADOG_APPLICATION_KEY"])

        strategy.install_hook(
          DatadogEmitter.new(logger, dogapi, @options.deployment_name))
      end

      strategy.deploy!

      if @options.promote_branch
        strategy.promote_to!(@options.promote_branch)
      end
    end
  end
end
