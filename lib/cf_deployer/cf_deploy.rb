require_relative 'cli'
require_relative 'release_repo'
require_relative 'deployment'
require_relative 'bosh'
require_relative 'manifest'

class CfDeploy
  RUBY_VERSION = "1_9_3".freeze
  GO_VERSION = "1.1.2".freeze
  GO_PACKAGE = "ci".freeze
     
  def initialize(options)
    @options = options
  end
  
  def deploy_to_aws(runner)
    deployments_repo = Repo.new(runner, "./repos", "deployments-aws", "master")
    deployments_repo.sync!

    deployment = Deployment.new(File.join(deployments_repo.path, @options.deploy_env))

    bosh = Bosh.new(runner, deployment.bosh_environment, interactive: false)

    release_repo = ReleaseRepo.new(runner, "./repos", @options.release_name, @options.deploy_branch)
    release_repo.sync!

    new_manifest = Manifest.new(runner).generate(release_repo.path, "aws", deployment.stub_files)

    bosh.create_and_upload_release(release_repo.path, final: false)

    bosh.deploy(new_manifest)

    release_repo.promote(@options.promote_branch) if @options.promote_branch
  end

  def prod_run
    #log "Deploying CI #{@options}"
    #
    #Repo.checkout "prod-aws", "master" do |repo|
    #  deployment = Deployment.new("#{repo.path}/cf-aws-stub.yml", "#{repo.path}/cf-shared-secrets.yml", "#{repo.path}/bosh_environment")
    #end
    #bosh = Bosh.new(interactive: true, data_dog: true)
    #
    #ReleaseRepo.checkout @options.release_name, @options.deploy_branch do |repo|
    #  repo.bump_version
    #  repo.whats_in_the_deploy(interactive: true)
    #
    #  new_manifest = "new_deployment.yml"
    #  release.create_manifest(new_manifest)
    #  deployment.merge_manifest(new_manifest)
    #  old_manifest = bosh.download_manifest(@options.deploy_env)
    #  run! "spiff diff #{old_manifest} #{new_manifest}"
    #
    #  deployment.source_bosh_environment
    #  bosh.create_and_upload_release(final: true)
    #  bosh.deploy(deployment.manifest)
    #
    #  repo.tag(@options.tag)
    #end
  end

  def ci_vsphere_run
  end

  def warden_run
  end
end