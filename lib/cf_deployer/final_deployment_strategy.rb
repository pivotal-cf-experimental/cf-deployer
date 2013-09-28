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

      @bosh.create_and_upload_final_release(
        @release.path, private_config)

      manifest = @manifest.generate!(@deployment.stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def do_promote_to(branch)
      @release.promote_final_release(branch)
    end
  end
end
