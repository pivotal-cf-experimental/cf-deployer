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
    run! "bundle install --without development test" if File.exists?("Gemfile")
  end

  def clean
    log "Cleaning repo #{Dir.pwd}"

    run! "git reset --hard"
    run! "git clean -fd"
    run! "git fetch"
    run! "git checkout #{@branch}"
    run! "git submodule update --init --recursive"
  end

  private

  def initialize(path, branch)
    @path = path
    @branch = branch
  end
end
