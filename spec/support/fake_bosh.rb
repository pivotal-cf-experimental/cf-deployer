module CfDeployer
  class FakeBosh
    attr_reader :dev_release, :dev_release_name, :final_release, :final_release_name, :private_config, :deployment, :deployed, :uploaded_release

    def create_dev_release(release_path, release_name)
      @dev_release = release_path
      @dev_release_name = release_name
    end

    def create_final_release(release_path, release_name, private_config)
      raise "did not specify private config" unless private_config

      @final_release = release_path
      @final_release_name = release_name
      @private_config = private_config
    end

    def upload_release(release_path)
      @uploaded_release = release_path
    end

    def set_deployment(manifest)
      @deployment = manifest
    end

    def deploy
      unless @dev_release || @final_release
        raise "did not create"
      end

      unless @uploaded_release
        raise "did not upload release"
      end

      unless [@final_release, @dev_release].include?(@uploaded_release)
        raise "uploaded release is not the one you intend to deploy"
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
