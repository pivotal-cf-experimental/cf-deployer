require "cf_deployer/deployment_strategy"

module CfDeployer
  class DevDeploymentStrategy < DeploymentStrategy
    def deploy!
      @bosh.create_and_upload_dev_release(@release.path)

      manifest = @manifest.generate!(@deployment.stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def promote_to!(branch)
      @release.promote_dev_release(branch)
    end
  end
end
