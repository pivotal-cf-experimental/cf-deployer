require "cf_deployer/deployment_strategy"

module CfDeployer
  class DevDeploymentStrategy < DeploymentStrategy
    private

    def do_deploy
      @bosh.create_and_upload_dev_release(@release.path, @release_name)

      manifest = @manifest.generate!(@deployment.stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def do_promote_to(branch)
      @release.promote_dev_release(branch)
    end
  end
end
