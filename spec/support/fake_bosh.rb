module CfDeployer
  class FakeBosh
    attr_reader :dev_release, :final_release, :private_config, :deployment, :deployed

    def create_and_upload_dev_release(release_path, release_name)
      @dev_release = [release_path, release_name]
    end

    def create_and_upload_final_release(release_path, release_name, private_config)
      raise "did not specify private config" unless private_config

      @final_release = [release_path, release_name]
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

    def director_uuid
      "director-uuid"
    end
  end
end
