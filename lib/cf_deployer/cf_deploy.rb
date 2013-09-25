require 'cf_deployer/cli'
require 'cf_deployer/release_repo'
require 'cf_deployer/deployment'
require 'cf_deployer/bosh'
require 'cf_deployer/manifest'

module CfDeployer
  class CfDeploy
    RUBY_VERSION = "1_9_3".freeze
    GO_VERSION = "1.1.2".freeze
    GO_PACKAGE = "ci".freeze

    def initialize(logger, options)
      @logger = logger
      @options = options
    end

    def deploy(infrastructure, runner)
      deployments_repo = Repo.new(@logger, runner, @options.repos_path, @options.deployments_repo, "master")
      deployments_repo.sync!

      release_repo = ReleaseRepo.new(@logger, runner, @options.repos_path, @options.release_name, @options.deploy_branch)
      release_repo.sync!

      deployment = Deployment.new(File.join(deployments_repo.path, @options.deploy_env))

      bosh = Bosh.new(@logger, runner, deployment.bosh_environment, interactive: @options.interactive)

      bosh.create_and_upload_release(release_repo.path, final: false)

      new_manifest = Manifest.new(runner).generate(release_repo.path, infrastructure, deployment.stub_files)
      bosh.deployment(new_manifest)

      bosh.deploy

      release_repo.promote_dev_release(@options.promote_branch) if @options.promote_branch
    end
  end
end