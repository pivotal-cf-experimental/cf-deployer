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

    def initialize(options, logger, runner=CfDeployer::CommandRunner.new(logger, options.dry_run))
      @options = options
      @logger = logger
      @runner = runner
    end

    def prepare
      deployments_repo = Repo.new(@logger, @runner, @options.repos_path, @options.deployments_repo, "origin/master")

      deployments_repo.sync! unless @options.dirty

      # This is a kludge around the fact that release repos contain their own deployment manifest generation scripts.
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

      @deployment = Deployment.new(File.join(deployments_repo.path, @options.deployment_name))

      bosh = Bosh.new(
        @logger, @runner, deployment.bosh_environment,
        interactive: @options.interactive,
        rebase: @options.rebase,
        dirty: @options.dirty,
        dry_run: @options.dry_run
      )

      @manifest_generator =
        ReleaseManifestGenerator.new(
          @runner, authoritative_release_repo, @options.infrastructure, "new_deployment.yml")

      build_deployment_strategy(deployment, bosh, manifest_generator, releases)
    end

    private

    def build_deployment_strategy(deployment, bosh, manifest_generator, releases)
      strategy_type =
        if @options.final_release
          FinalDeploymentStrategy
        else
          DevDeploymentStrategy
        end

      needs_explicit_director_uuid = @options.infrastructure == "warden"
      if needs_explicit_director_uuid
        manifest_generator.overrides["director_uuid"] = bosh.director_uuid
      end

      if @options.manifest_domain
        manifest_generator.overrides["properties"] ||= {}
        manifest_generator.overrides["properties"]["domain"] = @options.manifest_domain
      end

      @strategy = strategy_type.new(bosh, deployment, manifest_generator, releases)
    end
  end
end
