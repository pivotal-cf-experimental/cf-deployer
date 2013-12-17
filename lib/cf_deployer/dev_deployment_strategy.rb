require "cf_deployer/deployment_strategy"

module CfDeployer
  class DevDeploymentStrategy < DeploymentStrategy
    private

    def do_deploy
      @releases.each do |name, repo|
        @bosh.create_and_upload_dev_release(repo.path, name)
      end

      manifest = @manifest.generate!(stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def do_promote_to(branch)
      @releases.each do |_, repo|
        repo.promote_dev_release(branch)
      end
    end

    def stub_files
      @deployment.stub_files
    end
  end
end
