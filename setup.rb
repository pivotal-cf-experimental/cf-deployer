require_relative 'cmd_runner'

class Setup
  include CmdRunner
  
  def use_ruby(version)
    log "Setting up ruby"
    
    run! "/usr/local/share/chruby/chruby.sh"
    run! "chruby #{version}"
  end
  
  def use_go(version, package)
    log "Setting up go"
    
    run! "source ~/.gvm/scripts/gvm"
    run! "gvm install go#{version}" unless run? "gvm list | grep go#{version}"
    run! "gvm pkgset create #{package}" unless run? "gvm pkgset list | grep #{package}"
    run! "gvm pkgset use #{package}"
  end
  
  def install_spiff
    log "Installing Spiff"
    
    run! "go get -v github.com/vito/spiff"
  end
end