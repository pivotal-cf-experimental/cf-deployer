require_relative "cmd_runner"
require_relative "data_dog"

class Bosh
  include CmdRunner
  
  def initialize(bosh_environment_path, opts)
    @options = {interactive: true, data_dog: true}.merge(opts)
    @bosh_environment_path = bosh_environment_path
    @data_dog = DataDog.new
  end
  
  def create_and_upload_release(opts)
    opts = {final: false}.merge(opts)
    log "Create and upload an release #{opts}"
    
    create_release(opts[:final])
    upload_release
  end
  
  def deploy(manifest_path)
    log "Deploy #{manifest_path}"
    
    bosh! "deployment #{manifest_path}"
    @data_dog.emit do
      bosh! "deploy"
    end
  end

  def download_manifest(deploy_env)
    log "Downloading the manifest for #{deploy_env}"

    current_manifest = "current_manifest.yml"
    bosh! "download manifest cf-#{deploy_env} #{current_manifest}"
    current_manifest
  end

  def deployment(manifest)
    log "Setting manifest to #{manifest}"

    bosh! "deployment #{manifest}"
  end

  def login
    bosh! "target $BOSH_DIRECTOR"
    bosh! "login $BOSH_USER $BOSH_PASSWORD"
  end
  
  private
  
  def create_release(final)
    bosh! "create release#{" --force" unless final}"
    
    if final
      run! "git checkout -- config/final.yml" # until there's a solid BOSH on rubygems >:(
      bosh! "create release --final"
    end
  end
  
  def upload_release
    bosh! "upload release"
  end
  
  def bosh!(cmd)
    run! "source #{@bosh_environment_path} && bundle exec bosh#{" -n" unless @options[:interactive]} #{cmd}"
  end
end
