require 'yaml'

module CfDeployer
  class ReleaseManifest
    def initialize(runner, release, infrastructure, destination)
      @runner = runner
      @release = release
      @infrastructure = infrastructure
      @destination = destination
    end

    def generate!(stub_files)
      gospace = File.expand_path("./gospace")

      FileUtils.mkdir_p(gospace)
      @runner.run! "go get -u -v github.com/vito/spiff",
        environment: { "GOPATH" => gospace }

      @runner.run! "#{@release.path}/generate_deployment_manifest #{@infrastructure} #{stub_files.join(" ")} > #{@destination}",
        environment: { "PATH" => "#{gospace}/bin:/usr/bin:/bin" }

      File.expand_path(@destination)
    end
  end
end
