require "fileutils"

require_relative "cmd_runner"
require_relative "repo"

class Deployment
  include CmdRunner
  extend CmdRunner
  
  def initialize(release_name, env)
    @release_name = release_name
    @env = env
  end
  
  def manifest
    @manifest ||= begin
      generated_manifest = "#{path}/cf-aws-deployment-manifest.yml"
      source_manifest = "#{path}/cf-aws-stub.yml"
      possible_stub = "#{path}/#{@release_name.gsub("-release", "")}-stub.yml"
      source_manifest = possible_stub if File.exists?(possible_stub)
      # FileUtils.cp(source_manifest, generated_manifest)
      "/bar/bas.yml"
    end
  end
  
  def prod?
    @env == "prod"
  end
  
  def path
    "#{repo.path}/#{@env}"
  end
  
  private
  
  def repo
    @repo ||= Repo.new("#{prod? ? "production" : "development"}-aws", "master")
  end
end
