module CfDeployer
  class Bosh
    RELEASE_NAME = "cf".freeze
    DEV_CONFIG = "config/dev.yml".freeze
    FINAL_CONFIG = "config/final.yml".freeze

    def initialize(logger, runner, bosh_environment, options = {})
      @logger = logger
      @runner = runner
      @options = { interactive: true }.merge(options)
      @bosh_environment = bosh_environment
    end

    def create_and_upload_release(release_path, options = {})
      options = { final: false }.merge(options)

      @runner.run! "cd #{release_path} && git checkout -- #{FINAL_CONFIG}" # until there's a solid BOSH on rubygems >:(

      @logger.log_message "setting release name to '#{RELEASE_NAME}'"
      set_release_name(release_path)

      @logger.log_message "creating #{options[:final] ? "final release" : "release"}"
      create_release(release_path, options[:final])

      @logger.log_message "uploading release"
      upload_release(release_path)
    end

    def deployment(manifest)
      @logger.log_message "setting deployment to #{manifest}"
      run_with_clean_env("bundle exec bosh #{bosh_flags} deployment #{manifest}")
    end

    def deploy
      @logger.log_message "DEPLOYING!"
      run_with_clean_env("yes yes | bundle exec bosh #{bosh_flags(true)} deploy")
    end

    private

    def set_release_name(release_path)
      dev_config = File.expand_path(File.join(release_path, DEV_CONFIG))

      dev = File.exists?(dev_config) ? YAML.load_file(dev_config) : {}

      dev["dev_name"] = RELEASE_NAME

      FileUtils.mkdir_p(File.dirname(dev_config))

      File.open(dev_config, "w") do |io|
        YAML.dump(dev, io)
      end
    end

    def create_release(release_path, final)
      run_with_clean_env("cd #{release_path} && bundle exec bosh #{bosh_flags} create release#{" --final" if final}")
    end

    def upload_release(release_path)
      run_with_clean_env("cd #{release_path} && bundle exec bosh #{bosh_flags} upload release --skip-if-exists")
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
end