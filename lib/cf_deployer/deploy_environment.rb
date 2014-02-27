require "cf_deployer/release_repo"
require "cf_deployer/deployment"
require "cf_deployer/bosh"
require "cf_deployer/release_manifest_generator"
require "cf_deployer/dev_deployment_strategy"
require "cf_deployer/final_deployment_strategy"
require "cf_deployer/command_runner"

module CfDeployer
  class DeployEnvironment
    attr_reader :deployment, :strategy, :manifest_generator, :options, :runner

    def initialize(options, logger, runner = CfDeployer::CommandRunner.new(logger, options.dry_run))
      @options = options
      @logger = logger
      @runner = runner
    end

    def prepare
      deployments_repo = Repo.new(@logger, @runner, options.repos_path, options.deployments_repo, "origin/master")
      deployments_repo.sync! unless options.dirty

      release_repo = ReleaseRepo.new(@logger, @runner, options.repos_path, options.release_repo, options.release_ref)
      release_repo.sync! unless options.dirty

      @deployment = Deployment.new(File.join(deployments_repo.path, options.deployment_name))

      bosh = Bosh.new(
        @logger, runner, deployment.bosh_environment,
        interactive: options.interactive,
        rebase: options.rebase,
        dirty: options.dirty,
        dry_run: options.dry_run
      )

      @manifest_generator = ReleaseManifestGenerator.new(@runner, release_repo, options.infrastructure, "new_deployment.yml")

      build_deployment_strategy(bosh, release_repo)
    end

    private

    def build_deployment_strategy(bosh, release_repo)
      strategy_type =
        if options.final_release
          FinalDeploymentStrategy
        else
          DevDeploymentStrategy
        end

      needs_explicit_director_uuid = options.infrastructure == "warden"
      if needs_explicit_director_uuid
        manifest_generator.overrides["director_uuid"] = bosh.director_uuid
      end

      if options.manifest_domain
        manifest_generator.overrides["properties"] ||= {}
        manifest_generator.overrides["properties"]["domain"] = options.manifest_domain
      end

      @strategy = strategy_type.new(bosh, deployment, manifest_generator, options.release_name, release_repo)
    end
  end
end
