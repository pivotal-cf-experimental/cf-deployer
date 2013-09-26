require 'cf_deployer/cli'
require 'cf_deployer/release_repo'
require 'cf_deployer/deployment'
require 'cf_deployer/bosh'
require 'cf_deployer/manifest'

module CfDeployer
  class CfDeploy
    def initialize(options)
      @options = options
    end

    def deploy(logger, runner)
      deployments_repo = Repo.new(logger, runner, @options.repos_path, @options.deployments_repo, "master")
      deployments_repo.sync!

      release_repo = ReleaseRepo.new(logger, runner, @options.repos_path, @options.release_name, @options.deploy_branch)
      release_repo.sync!

      deployment = Deployment.new(File.join(deployments_repo.path, @options.deploy_env))

      bosh = Bosh.new(logger, runner, deployment.bosh_environment, interactive: @options.interactive)

      bosh.create_and_upload_dev_release(release_repo.path)

      new_manifest = Manifest.new(runner).generate(release_repo.path, @options.infrastructure, deployment.stub_files)
      bosh.deployment(new_manifest)

      bosh.deploy

      release_repo.promote_dev_release(@options.promote_branch) if @options.promote_branch
    end
  end
end
