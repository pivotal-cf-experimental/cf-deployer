require 'cf_deployer/shell_out'

module CfDeployer
  class Repo
    def initialize(logger, runner, repos_path, repo_uri, ref)
      @logger = logger
      @runner = runner
      @repos_path = repos_path
      @repo_uri = repo_uri
      @ref = ref
    end

    def sync!
      unless cloned?
        log_message 'not found; cloning'
        @runner.run! "mkdir -p #@repos_path"
        @runner.run! "git clone #@repo_uri #{path}"
      end

      unless git_toplevel
        log_message 'not a repo; skipping'
        return
      end

      log_message "syncing with #@ref"
      sync_with_origin
    end

    def path
      if File.directory?(@repo_uri)
        @repo_uri
      else
        File.join(@repos_path, repo_name)
      end
    end

    def cloned?
      File.exists?(path)
    end

    private

    def log_message(message)
      @logger.log_message "#{repo_display_name}: #{message}"
    end

    def repo_display_name
      "#{repo_owner}/#{repo_name}"
    end

    def repo_name
      File.basename(@repo_uri).sub(/\.git$/, '')
    end

    def repo_owner
      @repo_uri[/[\/:]([^\/]+)\/([^\.:\/]+)(\.git)?$/, 1]
    end

    def sync_with_origin
      run_git! 'reset --hard'
      run_git! 'clean --force --force -d'
      run_git! 'fetch'
      run_git! "checkout #{@ref}"
      run_git! 'clean --force --force -d'
      run_git! 'submodule sync --recursive'
      run_git! 'submodule init'
      run_git! "submodule status | awk '{print $2}' | xargs -P10 -n1 git submodule update --init --recursive"
      run_git! 'submodule foreach --recursive git clean --force --force -d'
    end

    def run_git!(command)
      @runner.run! "cd #{git_toplevel} && git #{command}"
    end

    def git_toplevel
      return @git_toplevel unless @git_toplevel.nil?

      return unless File.directory?(path)

      Dir.chdir(path) do
        top = ShellOut.capture_output('git rev-parse --show-toplevel 2>/dev/null')

        if $?.success?
          @git_toplevel = top.chomp
        else
          @git_toplevel = false
        end
      end
    end
  end
end
