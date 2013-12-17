require "cf_deployer/dev_deployment_strategy"

module CfDeployer
  class WardenDeploymentStrategy < DevDeploymentStrategy
    private
    def stub_files
      director_uuid_stub = @deployment.director_uuid_stub_file(@bosh.director_uuid)
      super + [director_uuid_stub]
    end
  end
end
