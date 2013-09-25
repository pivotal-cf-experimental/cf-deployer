require 'yaml'

class Manifest
  def initialize(runner)
    @runner = runner
  end

  def generate(release_path, infrastructure, stub_files)
    new_manifest_path = "new_deployment.yml"

    @runner.run! "#{release_path}/generate_deployment_manifest #{infrastructure} #{stub_files.join(" ")}",
      out: File.open(new_manifest_path, "w")

    File.expand_path(new_manifest_path)
  end
end