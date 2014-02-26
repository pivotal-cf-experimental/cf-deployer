require "cf_deployer/deployment_strategy"

module CfDeployer
  class FinalDeploymentStrategy < DeploymentStrategy
    class MissingPrivateConfig < RuntimeError
      def message
        "config/private.yml does not exist in your deployment"
      end
    end

    def create_release
      raise MissingPrivateConfig unless @deployment.private_config

      @bosh.create_final_release(@release_repo.path, @release_name, @deployment.private_config)
    end

    def upload_release
      @bosh.upload_release(@release_repo.path)
    end

    def promote_release(branch)
      @release_repo.promote_final_release(branch)
    end
  end
end
