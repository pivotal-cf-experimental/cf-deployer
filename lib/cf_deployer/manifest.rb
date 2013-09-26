require 'yaml'

module CfDeployer
  class ReleaseManifestGenerator
    def initialize(runner, release, infrastructure)
      @runner = runner
      @release = release
      @infrastructure = infrastructure
    end

    def generate(stub_files)
      new_manifest_path = "new_deployment.yml"

      gospace = File.expand_path("./gospace")

      FileUtils.mkdir_p(gospace)
      @runner.run! "go get -u -v github.com/vito/spiff",
        environment: { "GOPATH" => gospace }

      @runner.run! "#{@release.path}/generate_deployment_manifest #{@infrastructure} #{stub_files.join(" ")} > #{new_manifest_path}",
        environment: { "PATH" => "#{gospace}/bin:/usr/bin:/bin" }

      File.expand_path(new_manifest_path)
    end
  end
end
