module CfDeployer
  class DeploymentStrategy
    def initialize(bosh, deployment, manifest, release_name, release_repo)
      @bosh = bosh
      @deployment = deployment
      @manifest = manifest
      @release_name = release_name
      @release_repo = release_repo

      @hooks = []
    end

    def install_hook(hook)
      @hooks << hook
    end

    def deploy!
      @hooks.each(&:pre_deploy)
      do_deploy
      @hooks.each(&:post_deploy)
      nil
    end

    def promote_to!(branch)
      do_promote_to(branch)
    end

    private

    def do_deploy
      raise NotImplementedError
    end

    def do_promote_to(branch)
      raise NotImplementedError
    end
  end
end
