require "cf_deployer/deployment_strategy"

module CfDeployer
  class DevDeploymentStrategy < DeploymentStrategy
    private

    def do_deploy
      @bosh.create_dev_release(@release_repo.path, @release_name)
      @bosh.upload_release(@release_repo.path)

      manifest = @manifest.generate!(stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def do_promote_to(branch)
      @release_repo.promote_dev_release(branch)
    end

    def stub_files
      @deployment.stub_files
    end
  end
end
