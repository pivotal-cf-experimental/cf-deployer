require "dogapi"

require "cf_deployer/cli"
require "cf_deployer/release_repo"
require "cf_deployer/deployment"
require "cf_deployer/bosh"
require "cf_deployer/manifest_generator"
require "cf_deployer/dev_deployment_strategy"
require "cf_deployer/warden_deployment_strategy"
require "cf_deployer/final_deployment_strategy"
require "cf_deployer/hooks/datadog_emitter"
require "cf_deployer/hooks/token_installer"
require "cf_deployer/command_runner"

module CfDeployer
  class CfDeploy
    def initialize(options, logger)
      @options = options
      @logger = logger
      @runner = CfDeployer::CommandRunner.new(logger, options.dry_run)
    end

    def deploy
      deployments_repo = Repo.new(@logger, @runner, @options.repos_path, @options.deployments_repo, "origin/master")

      deployments_repo.sync! unless @options.dirty

      # This is a cludge around the fact that release repos contain their own deployment manifest generation scripts.
      # rather than adding another flag, this just makes it so the last release repo listed is the source of the manifest generation.
      # It really should be its own separate concept but it's currently tied to releases.
      #
      # how it probably should be:
      #
      # releases (cf, services, dea, ...) ->
      #   deployment (staging/prod; controls composition of releases) ->
      #   environment (my_environment; provides infrastructure stubs, bosh director info, etc.)
      authoritative_release_repo = nil

      releases = {}
      @options.release_names.zip(@options.release_repos, @options.release_refs) do |name, repo, ref|
        release_repo = ReleaseRepo.new(
          @logger, @runner, @options.repos_path, repo, ref)

        release_repo.sync! unless @options.dirty

        releases[name] = release_repo

        authoritative_release_repo = release_repo
      end

      deployment = Deployment.new(File.join(deployments_repo.path, @options.deployment_name))

      bosh = Bosh.new(
        @logger, @runner, deployment.bosh_environment,
        interactive: @options.interactive,
        rebase: @options.rebase,
        dirty: @options.dirty,
        dry_run: @options.dry_run
      )

      manifest_generator =
        ReleaseManifestGenerator.new(
          @runner, authoritative_release_repo, @options.infrastructure, "new_deployment.yml")

      strategy = build_deployment_strategy(deployment, bosh, manifest_generator, releases)

      install_deployment_hooks(strategy, deployment, manifest_generator)

      strategy.deploy!

      promote_branch(strategy)
    end

    private
    def install_deployment_hooks(strategy, deployment, manifest_generator)
      install_datadog_hook(strategy, deployment.bosh_environment)

      install_token_hook(strategy, manifest_generator)
    end

    def promote_branch(strategy)
      return unless @options.promote_branch
      strategy.promote_to!(@options.promote_branch)
    end

    def install_token_hook(strategy, manifest_generator)
      return unless @options.install_tokens
      strategy.install_hook TokenInstaller.new(@logger, manifest_generator, @runner)
    end

    def build_deployment_strategy(deployment, bosh, manifest_generator, releases)
      strategy_type =
        if @options.final_release
          FinalDeploymentStrategy
        elsif @options.infrastructure == "warden"
          WardenDeploymentStrategy
        else
          DevDeploymentStrategy
        end

      strategy_type.new(
        bosh, deployment, manifest_generator, releases)
    end

    def install_datadog_hook(strategy, env)
      if env["DATADOG_API_KEY"]
        dogapi = Dogapi::Client.new(
          env["DATADOG_API_KEY"],
          env["DATADOG_APPLICATION_KEY"])

        strategy.install_hook(
          DatadogEmitter.new(@logger, dogapi, @options.deployment_name))
      end
    end
  end
end
