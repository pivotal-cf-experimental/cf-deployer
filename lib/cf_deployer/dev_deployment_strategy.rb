require "cf_deployer/deployment_strategy"

module CfDeployer
  class DevDeploymentStrategy < DeploymentStrategy

    def create_release
      @bosh.create_dev_release(@release_repo.path, @release_name)
    end

    def upload_release
      @bosh.upload_release(@release_repo.path)
    end

    def promote_to!(branch)
      @release_repo.promote_dev_release(branch)
    end

    private

    def do_deploy
      create_release
      upload_release

      manifest = @manifest.generate!(@deployment.stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end
  end
end
