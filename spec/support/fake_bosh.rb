module CfDeployer
  class FakeBosh
    attr_reader :dev_release, :final_release, :private_config, :deployment, :deployed

    def create_and_upload_dev_release(release_path)
      @dev_release = release_path
    end

    def create_and_upload_final_release(release_path, private_config)
      raise "did not specify private config" unless private_config

      @final_release = release_path
      @private_config = private_config
    end

    def set_deployment(manifest)
      @deployment = manifest
    end

    def deploy
      unless @dev_release || @final_release
        raise "did not create or upload release"
      end

      unless @deployment
        raise "did not set deployment"
      end

      @deployed = true
    end
  end
end
