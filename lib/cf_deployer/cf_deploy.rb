require_relative 'cli'
require_relative 'release_repo'
require_relative 'deployment'
require_relative 'bosh'
require_relative 'manifest'

class CfDeploy
  include CmdRunner
  
  RUBY_VERSION = "1_9_3".freeze
  GO_VERSION = "1.1.2".freeze
  GO_PACKAGE = "ci".freeze
     
  def initialize(options)
    @options = options
  end
  
  def ci_aws_run
    log "Deploying CI #{@options}"

    fail "promote branch is required" if @options.promote_branch.nil?

    deployment = Repo.checkout "deployments-aws", "master" do |repo|
      Deployment.new("#{@options.deploy_env}/bosh_environment", ["#{@options.deploy_env}/cf-aws-stub.yml"])
    end

    bosh = Bosh.new(deployment.bosh_environment_path, interactive: false, data_dog: true)

    ReleaseRepo.checkout(@options.release_name, @options.deploy_branch) do |release|
      bosh.login

      old_manifest = bosh.download_manifest(@options.deploy_env)
      new_manifest = Manifest.new(old_manifest, deployment.stub_files).generate("aws")

      bosh.deployment(new_manifest)

      bosh.create_and_upload_release(final: false)
      bosh.deploy(deployment.manifest)
    
      release.promote(@options.promote_branch)
    end
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