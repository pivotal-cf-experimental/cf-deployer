require 'cf_deployer/shell_out'

module CfDeployer
  class Repo
    def initialize(logger, runner, repos_path, uri, ref)
      @logger = logger
      @runner = runner
      @repos_path = repos_path
      @uri = uri
      @ref = ref
    end

    def sync!
      @runner.run! "rm -rf #{path}"
      @runner.run! "mkdir -p #{path}"
      @runner.run! "git clone --branch #{@ref} #{@uri} #{path}"

      unless git_toplevel
        log_message 'not a repo; skipping'
        return
      end

      log_message "syncing with #{@ref}"
      sync_with_origin
    end

    def use_local_blob_cache(blob_cache_dir)
      @runner.run! "rm -rf #{path}/.blobs"
      @runner.run! "mkdir -p #{blob_cache_dir}"
      @runner.run! "ln -s #{blob_cache_dir} #{path}/.blobs"
    end

    def path
      File.directory?(@uri) ? @uri : File.join(@repos_path, repo_name)
    end

    private

    def log_message(message)
      @logger.log_message "#{repo_display_name}: #{message}"
    end

    def repo_display_name
      "#{repo_owner}/#{repo_name}"
    end

    def repo_name
      File.basename(@uri).sub(/\.git$/, '')
    end

    def repo_owner
      @uri[/[\/:]([^\/]+)\/([^\.:\/]+)(\.git)?$/, 1]
    end

    def sync_with_origin
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
