module CfDeployer
  class FakeReleaseManifestGenerator
    attr_reader :stubs

    def initialize(destination)
      @destination = destination
    end

    def generate!(stubs)
      @stubs = stubs
      @destination
    end
  end
end
