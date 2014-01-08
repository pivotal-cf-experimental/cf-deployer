require 'yaml'
require 'cf_deployer/manifest'

module CfDeployer
  class ReleaseManifestGenerator
    def initialize(runner, release, infrastructure, destination)
      @runner = runner
      @release = release
      @infrastructure = infrastructure
      @destination = destination
    end

    def generate!(stub_files)
      gospace = File.expand_path("./gospace")

      FileUtils.mkdir_p(gospace)
      @runner.run! "go get -v github.com/cloudfoundry-incubator/spiff",
        environment: { "GOPATH" => gospace }

      @runner.run! "#{@release.path}/generate_deployment_manifest #{@infrastructure} #{stub_files.join(" ")} > #{@destination}",
        environment: { "PATH" => "#{gospace}/bin:/usr/bin:/bin" }

      File.expand_path(@destination)
    end

    def get_manifest
      ReleaseManifest.load_file(@destination)
    end
  end
end
