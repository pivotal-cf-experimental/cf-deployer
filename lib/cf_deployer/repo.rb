class Repo
  def initialize(runner, repos_path, repo_name, branch)
    @runner = runner
    @repos_path = repos_path
    @repo_name = repo_name
    @branch = branch
  end

  def sync!
    FileUtils.mkdir_p(@repos_path)

    unless cloned?
      @runner.run! "git clone git@github.com:cloudfoundry/#{@repo_name}.git #{path}"
    end

    sync_with_origin
  end

  def path
    File.join(@repos_path, @repo_name)
  end

  def cloned?
    File.exists?(path)
  end

  private

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
