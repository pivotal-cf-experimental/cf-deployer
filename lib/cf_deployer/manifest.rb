require 'yaml'

class Manifest
  include CmdRunner

  def initialize(old_manifest, stub_files)
    @old_manifest = old_manifest
    @stub_files = stub_files
  end

  def generate(infrastructure)
    log "Creating and diffing manifest"

    new_manifest = "new_deployment.yml"

    run! "./generate_deployment_manifest #{infrastructure} #{@stub_files.join(" ")} > #{new_manifest}"

    normalize_yaml @old_manifest

    run! "spiff diff #{@old_manifest} #{new_manifest}"

    new_manifest
  end

  private

  # syck doesn't do this stupid format:
  #
  #     some_big_string: ! 'ABC
  #
  #     DEF
  #
  #     GHI
  #
  #
  def normalize_yaml(file)
    YAML::ENGINE.yamler = "syck"

    yaml = YAML.load_file(file)

    File.open(file, "w") do |io|
      YAML.dump(yaml, io)
    end
  end
end