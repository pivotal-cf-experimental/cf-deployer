module CfDeployer
  class DeploymentStrategy
    def initialize(bosh, deployment, release, manifest_generator)
      @bosh = bosh
      @deployment = deployment
      @release = release
      @manifest_generator = manifest_generator
    end
  end
end
