module CfDeployer
  class DeploymentStrategy
    def initialize(bosh, deployment, release, manifest)
      @bosh = bosh
      @deployment = deployment
      @release = release
      @manifest = manifest
    end
  end
end
