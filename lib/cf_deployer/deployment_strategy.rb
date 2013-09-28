require "cfoundry"

module CfDeployer
  class DeploymentStrategy
    def initialize(bosh, deployment, release, manifest)
      @bosh = bosh
      @deployment = deployment
      @release = release
      @manifest = manifest

      @hooks = []
    end

    def install_hook(hook)
      @hooks << hook
    end

    def deploy!
      @hooks.each(&:pre_deploy)
      do_deploy
      @hooks.each(&:post_deploy)
    end

    def promote_to!(branch)
      do_promote_to(branch)
    end

    private

    def do_deploy
      raise NotImplementedError
    end

    def do_promote(branch)
      raise NotImplementedError
    end
  end
end
