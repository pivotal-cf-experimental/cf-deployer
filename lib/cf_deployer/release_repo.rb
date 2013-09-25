require_relative "command_runner"
require_relative "whats_in_the_deploy"
require_relative "repo"

class ReleaseRepo < Repo
  def promote(branch)
    log "Promoting #{Dir.pwd} to #{branch}"
  end
  
  def tag
    run! "git tag #{next_version}"
    run! "git push origin "
  end
  
  def bump_version
    log "Bumping #{Dir.pwd} version from #{previous_version} to #{next_version}"
  end
  
  def whats_in_the_deploy(opts)
    log "Checking what is in the deploy"
    return

    opts = { interactive: true }.merge(opts)
    output_html = "deploy.html"

    deploy = WhatsInTheDeploy.new(previous_version, branch)
    deploy.generate_html(output_html)

    if opts[:interactive]
      run! "open #{output_html}"

      puts "Is the deployment correct (yes/no)?"

      fail "Did not accept the deployment" if $stdin.gets.chomp !~ /^y/i
    end
  end
  
  private

  alias log puts

  def previous_version
    "prev"
  end

  def next_version
    "next"
  end
end