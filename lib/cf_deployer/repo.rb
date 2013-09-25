module CfDeployer
  class Repo
    def initialize(logger, runner, repos_path, repo_name, branch)
      @logger = logger
      @runner = runner
      @repos_path = repos_path
      @repo_name = repo_name
      @branch = branch
    end

    def sync!
      unless cloned?
        log_message "not found; cloning"
        @runner.run! "mkdir -p #@repos_path"
        @runner.run! "git clone git@github.com:cloudfoundry/#@repo_name.git #{path}"
      end

      log_message "syncing with origin/#@branch"
      sync_with_origin
    end

    def path
      File.join(@repos_path, @repo_name)
    end

    def cloned?
      File.exists?(path)
    end

    private

    def log_message(message)
      @logger.log_message "cloudfoundry/#@repo_name: #{message}"
    end

    def sync_with_origin
      run_git! "reset --hard"
      run_git! "clean --force -d"
      run_git! "fetch"
      run_git! "checkout origin/#{@branch}"
      run_git! "submodule update --init --recursive"
    end

    def run_git!(command)
      @runner.run! "cd #{path} && git #{command}"
    end
  end
end