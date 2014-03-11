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

    def create_release
      raise NotImplementedError
    end

    def upload_release
      raise NotImplementedError
    end

    def deploy_release
      with_deployment_hooks do
        manifest = @manifest.generate!(@deployment.stub_files)

        @bosh.set_deployment(manifest)
        @bosh.deploy
      end
    end

    def promote_release(branch)
      raise NotImplementedError
    end

    def tag_and_push_final_release(_)
      raise NoMethodError, 'This method is only available on a FinalDeploymentStrategy. Calling it elsewhere is a mistake.'
    end

    private

    def with_deployment_hooks
      @hooks.each(&:pre_deploy)
      yield
      @hooks.each(&:post_deploy)
    end
  end
end
