require "fileutils"

require_relative "cmd_runner"
require_relative "release_repo"

class Deployment
  include CmdRunner

  attr_reader :bosh_environment_path, :stub_files
  
  def initialize(bosh_environment_path, stub_files)
    @stub_files = stub_files.map { |stub_file| File.expand_path stub_file }
    @bosh_environment_path = File.expand_path bosh_environment_path
  end
  
  def prod?
    #@deployments_repo.include?("prod")
    false
  end
end
