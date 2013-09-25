require 'yaml'

module CfDeployer
  class Manifest
    def initialize(runner)
      @runner = runner
    end

    def generate(release_path, infrastructure, stub_files)
      new_manifest_path = "new_deployment.yml"

      gospace = File.expand_path("./gospace")

      FileUtils.mkdir_p(gospace)
      @runner.run! "go get -u -v github.com/vito/spiff",
        environment: { "GOPATH" => gospace }

      @runner.run! "#{release_path}/generate_deployment_manifest #{infrastructure} #{stub_files.join(" ")} > #{new_manifest_path}",
        environment: { "PATH" => "#{gospace}/bin:/usr/bin:/bin" }

      File.expand_path(new_manifest_path)
    end
  end
end