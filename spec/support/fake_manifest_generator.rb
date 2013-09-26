module CfDeployer
  class FakeManifestGenerator
    attr_reader :stubs

    def initialize(path_to_return)
      @path_to_return = path_to_return
    end

    def generate(stubs)
      @stubs = stubs
      @path_to_return
    end
  end
end
