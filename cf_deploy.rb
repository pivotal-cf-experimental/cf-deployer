#!/usr/bin/env ruby

require 'optparse'

require_relative 'cli'
require_relative 'setup'
require_relative 'repo'
require_relative 'deployment'
require_relative 'bosh'

class CfDeploy
  include CmdRunner
  
  RUBY_VERSION = "1_9_3".freeze
  GO_VERSION = "1_1_2".freeze
  GO_PACKAGE = "ci".freeze
     
  def initialize(options)
    @setup = Setup.new
    @deployment = Deployment.new(options.release_name, options.deploy_env)
    @bosh = Bosh.new(options.release_name, @deployment.path, interactive: @deployment.prod?, data_dog: true)
    @options = options
  end
  
  def run
    log "Deploying CI #{@options}"
    
    @setup.use_ruby(RUBY_VERSION)
    @setup.use_go(GO_VERSION, GO_PACKAGE)
    @setup.install_spiff

    Repo.checkout @options.release_name, @options.deploy_branch do |repo|    
      @bosh.create_and_upload_release(final: @deployment.prod?)
      repo.bump_version if @deployment.prod?
      @bosh.deploy(@deployment.manifest)
    
      repo.promote(@options.promote_branch) if @options.promote_branch
      repo.tag(@options.tag) if @options.tag
    end
  end
end

if __FILE__ == $PROGRAM_NAME  
  cf_deploy = CfDeploy.new(Cli.new(ARGV).parse!)
  cf_deploy.run
end
