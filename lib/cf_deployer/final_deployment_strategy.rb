require "cf_deployer/deployment_strategy"

module CfDeployer
  class FinalDeploymentStrategy < DeploymentStrategy
    class MissingPrivateConfig < RuntimeError
      def message
        "config/private.yml does not exist in your deployment"
      end
    end

    private

    def do_deploy
      private_config = @deployment.private_config
      raise MissingPrivateConfig unless private_config

      @bosh.create_final_release(@release_repo.path, @release_name, private_config)
      @bosh.upload_release(@release_repo.path)

      manifest = @manifest.generate!(@deployment.stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def do_promote_to(branch)
      @release_repo.promote_final_release(branch)
    end
  end
end
