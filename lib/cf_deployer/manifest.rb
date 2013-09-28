require 'yaml'

module CfDeployer
  class ReleaseManifest
    class ManifestNotGenerated < RuntimeError
      def message
        "manifest file has not generated yet"
      end
    end

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

    def api_endpoint
      find_in_manifest("properties", "cc", "srv_api_uri")
    end

    def admin_credentials
      users = find_in_manifest("properties", "uaa", "scim", "users")
      return unless users

      users.each do |user|
        username, password, _ = user.split("|")
        return username, password if username == "admin"
      end

      nil
    end

    private

    def find_in_manifest(*path)
      raise ManifestNotGenerated unless generated?

      parsed = YAML.load_file(@destination)

      path.inject(parsed) do |here, key|
        return here if !here.is_a?(Hash)
        return unless here.key?(key)

        here[key]
      end
    end

    def generated?
      File.exists?(@destination)
    end
  end
end
