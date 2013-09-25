class Bosh
  RELEASE_NAME = "cf".freeze
  DEV_CONFIG = "config/dev.yml".freeze
  FINAL_CONFIG = "config/final.yml".freeze

  def initialize(runner, bosh_environment, options = {})
    @runner = runner
    @options = { interactive: true }.merge(options)
    @bosh_environment = bosh_environment
  end
  
  def create_and_upload_release(release_path, options = {})
    options = { final: false }.merge(options)

    Dir.chdir(release_path) do
      set_release_name
      create_release(options[:final])
      upload_release
    end
  end

  def deploy(manifest)
    bosh! "deployment #{manifest}"

    yes_bosh! "deploy"
  end
  
  private

  def set_release_name
    dev = File.exists?(DEV_CONFIG) ? YAML.load_file(DEV_CONFIG) : {}

    dev["dev_name"] = RELEASE_NAME

    FileUtils.mkdir_p(File.dirname(DEV_CONFIG))

    File.open(DEV_CONFIG, "w") do |io|
      YAML.dump(dev, io)
    end
  end

  def create_release(final)
    @runner.run! "git checkout -- #{FINAL_CONFIG}" # until there's a solid BOSH on rubygems >:(

    bosh! "create release#{" --final" if final}"
  end
  
  def upload_release
    bosh! "upload release --skip-if-exists"
  end

  def bosh!(cmd, options = {}, &blk)
    run_with_clean_env("bundle exec bosh #{bosh_flags} #{cmd}", options, &blk)
  end

  # bosh shows different (often useful) output in interactive mode,
  # but we don't want the interactive bit.
  def yes_bosh!(cmd, options = {}, &blk)
    run_with_clean_env("yes yes | bundle exec bosh #{bosh_flags(true)} #{cmd}", options, &blk)
  end

  def run_with_clean_env(command, options = {}, &blk)
    @runner.run!(command, { environment: { "BOSH_CONFIG" => "" } }.merge(options), &blk)
  end

  def bosh_flags(interactive = @options[:interactive])
    flags = [
      "-t #{bosh_director}",
      "-u #{bosh_user}",
      "-p #{bosh_password}",
    ]

    flags << "-n" unless interactive

    flags.join(" ")
  end

  def bosh_director
    @bosh_environment["BOSH_DIRECTOR"]
  end

  def bosh_user
    @bosh_environment["BOSH_USER"]
  end

  def bosh_password
    @bosh_environment["BOSH_PASSWORD"]
  end
end
