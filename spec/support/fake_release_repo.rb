module CfDeployer
  class FakeReleaseRepo
    attr_reader :promoted_dev_release, :promoted_final_release, :tagged_and_pushed_final_release

    def initialize(path)
      @path = path
    end

    def path
      @path
    end

    def promote_dev_release(branch)
      @promoted_dev_release = branch
    end

    def promote_final_release(branch)
      @promoted_final_release = branch
    end

    def tag_and_push_final_release(branch)
      @tagged_and_pushed_final_release = branch
    end
  end
end
