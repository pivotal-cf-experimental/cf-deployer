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

      @releases.each do |name, repo|
        @bosh.create_final_release(repo.path, name, private_config)
        @bosh.upload_release(repo.path)
      end

      manifest = @manifest.generate!(@deployment.stub_files)

      @bosh.set_deployment(manifest)
      @bosh.deploy
    end

    def do_promote_to(branch)
      @releases.each do |_, repo|
        repo.promote_final_release(branch)
      end
    end
  end
end
