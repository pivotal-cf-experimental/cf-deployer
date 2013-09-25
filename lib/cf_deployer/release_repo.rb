require "cf_deployer/command_runner"
require "cf_deployer/whats_in_the_deploy"
require "cf_deployer/repo"

module CfDeployer
  class ReleaseRepo < Repo
    def promote(branch)
      log_message "promoting to #{branch}"
    end

    def tag
      log_message "creating and pushing tag #{next_version}"
      run! "git tag #{next_version}"
      run! "git push origin "
    end

    def bump_version
      log_message "bumping version from #{previous_version} to #{next_version}"
    end

    def whats_in_the_deploy(opts)
      log_message "checking what's in the deploy"
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

    def previous_version
      "prev"
    end

    def next_version
      "next"
    end
  end
end