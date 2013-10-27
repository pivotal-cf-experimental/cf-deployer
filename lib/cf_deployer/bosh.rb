require "tempfile"

module CfDeployer
  class Bosh
    DEV_CONFIG = "config/dev.yml".freeze
    FINAL_CONFIG = "config/final.yml".freeze

    attr_reader :bosh_output_file

    def initialize(logger, runner, bosh_environment, options = {})
      @logger = logger
      @runner = runner
      @options = { interactive: true, rebase: false }.merge(options)
      @bosh_environment = bosh_environment

      @bosh_config = Tempfile.new("bosh_config")
      @bosh_output_file = Tempfile.new("bosh_output")
    end

    def create_and_upload_dev_release(release_path, release_name)
      create_and_upload_release(release_path, release_name,
        rebase: @options.fetch(:rebase)
      )
    end

    def create_and_upload_final_release(release_path, release_name, private_config)
      create_and_upload_release(release_path, release_name,
        final: true,
        private_config: private_config,
        rebase: @options.fetch(:rebase)
      )
    end

    def set_deployment(manifest)
      @logger.log_message "setting deployment to #{manifest}"

      # despite passing -t for the target, this has to be set in the config file
      run_with_clean_env("bosh -n target #{bosh_director}")

      run_with_clean_env("bosh #{bosh_flags} deployment #{manifest}")
    end

    def deploy
      @logger.log_message "DEPLOYING!"

      if @options[:interactive]
        run_with_clean_env("bosh #{bosh_flags} deploy")
      else
        run_with_clean_env("yes yes | bosh #{bosh_flags(true)} deploy")
      end
    end

    private

    def create_and_upload_release(release_path, release_name, options={})
      final = options.fetch(:final, false)
      private_config = options[:private_config]
      rebase = options.fetch(:rebase, false)
      reset_bosh_final_build_stupidity(release_path, FINAL_CONFIG)

      @logger.log_message "setting release name to '#{release_name}'"
      set_release_name(release_path, release_name)

      @logger.log_message "creating dev release"
      create_release(release_path, false)

      if final
        reset_bosh_final_build_stupidity(release_path, FINAL_CONFIG, ".final_builds/")

        if private_config
          @logger.log_message "configuring blobstore"
          copy_private_config(release_path, private_config)
        end

        @logger.log_message "creating final release"
        create_release(release_path, final)
      end

      @logger.log_message "uploading release"
      upload_release(release_path, rebase)
    end

    def reset_bosh_final_build_stupidity(release_path, *to_checkout)
      # config/final.yml is constantly being set to the bosh cli version, and making the repo dirty
      # .final_builds/* is constantly messed up by base64-encoding shas. don't know why,
      @runner.run! "cd #{release_path} && git checkout -- #{to_checkout.join(" ")}"
    end

    def set_release_name(release_path, release_name)
      dev_config = File.expand_path(File.join(release_path, DEV_CONFIG))

      dev = File.exists?(dev_config) ? YAML.load_file(dev_config) : {}

      dev["dev_name"] = release_name

      FileUtils.mkdir_p(File.dirname(dev_config))

      File.open(dev_config, "w") do |io|
        YAML.dump(dev, io)
      end
    end

    def create_release(release_path, final)
      run_with_clean_env("cd #{release_path} && bosh #{bosh_flags} create release#{" --final" if final}")
    end

    def copy_private_config(release_path, source_path)
      @runner.run! "cp #{source_path} #{release_path}/config/private.yml"
    end

    def upload_release(release_path, rebase)
      upload_flags = %w(--skip-if-exists)
      upload_flags << '--rebase' if rebase
      begin
        run_with_clean_env("cd #{release_path} && bosh #{bosh_flags} upload release #{upload_flags.join(' ')} | tee #{bosh_output_file.path}")
      rescue CommandRunner::CommandFailed
        contents = File.read(@bosh_output_file.path)
        unless contents.match(/Rebase is attempted without any job or package changes/) then raise end
      end
    end

    def bosh!(cmd, options = {}, &blk)
      run_with_clean_env("bosh #{bosh_flags} #{cmd}", options, &blk)
    end

    # bosh shows different (often useful) output in interactive mode,
    # but we don't want the interactive bit.
    def yes_bosh!(cmd, options = {}, &blk)
      run_with_clean_env("yes yes | bosh #{bosh_flags(true)} #{cmd}", options, &blk)
    end

    def run_with_clean_env(command, options = {}, &blk)
      @runner.run!(command, { environment: { "BOSH_CONFIG" => @bosh_config.path } }.merge(options), &blk)
    end

    def bosh_flags(interactive = @options[:interactive])
      flags = [
        "-C #{bosh_cache_directory}",
        "-t #{bosh_director}",
        "-u #{bosh_user}",
        "-p #{bosh_password}",
      ]

      flags << "-n" unless interactive

      flags.join(" ")
    end

    def bosh_cache_directory
      @bosh_cache_directory ||= Dir.mktmpdir
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
