require 'yaml'
require 'cf_deployer/release_manifest'

module CfDeployer
  class ReleaseManifestGenerator
    attr_reader :overrides

    def initialize(runner, release, infrastructure, destination)
      @runner = runner
      @release = release
      @infrastructure = infrastructure
      @destination = destination
      @overrides = {}
    end

    def generate!(stub_files)
      gospace = File.expand_path("./gospace")

      FileUtils.mkdir_p(gospace)
      @runner.run!("go get -v github.com/cloudfoundry-incubator/spiff", environment: {"GOPATH" => gospace})

      overrides_file = Tempfile.new("overrides")
      begin
        YAML.dump(overrides, overrides_file.to_io)
        overrides_file.close

        all_stubs = stub_files
        unless overrides.empty?
          all_stubs << overrides_file.path
        end

        @runner.run!("#{@release.path}/generate_deployment_manifest #{@infrastructure} #{all_stubs.join(" ")} > #{@destination}",
                     environment: {"PATH" => "#{gospace}/bin:/usr/bin:/bin"})

        File.expand_path(@destination)
      ensure
        overrides_file.unlink
      end
    end

    def get_manifest
      ReleaseManifest.load_file(@destination)
    end
  end
end
