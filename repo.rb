require_relative "cmd_runner"

class Repo
  include CmdRunner
  
  attr_reader :path, :branch
  
  def self.checkout(path, branch)
    unless File.directory?(path)
      log "Checking out repo #{path}/#{branch}"
      run! "git clone --depth 1 --recursive --branch #{branch} git@github.com:cloudfoundry/#{path}.git"
    end
    
    raise "Failed to clone #{path}/#{branch}" unless File.directory?(path)

    Dir.chdir(path) do    
      repo = new(path, branch)
      repo.clean
      repo.bundle_install
      yield repo
    end
  end
  
  def bundle_install
    run! "bundle install --without development test"
  end
  
  def clean
    log "Cleaning repo #{Dir.pwd}"
      
    run! "git reset --hard"
    run! "git clean -fd"
    run! "git fetch"
    run! "git checkout origin/$branch"
    run! "git submodule update --init --recursive --depth 1"
  end
  
  def promote(branch)
    log "Promoting #{Dir.pwd} to #{branch}"
  end
  
  def tag(tag_name)
    log "Tagging repo #{Dir.pwd} with #{tag_name}"
  end
  
  def bump_version
    version = "foo"
    log "Bumping version #{Dir.pwd} to #{version}"
  end
  
  private
  
  def initialize(path, branch)
    @path = path
    @branch = branch
  end
end