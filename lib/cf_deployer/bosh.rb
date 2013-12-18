require "tempfile"
require "cf_deployer/command_runner"

module CfDeployer
  class Bosh
    DEV_CONFIG = "config/dev.yml".freeze
    FINAL_CONFIG = "config/final.yml".freeze

    attr_reader :bosh_output_file

    def initialize(logger, runner, bosh_environment, options = {})
      @logger = logger
      @runner = runner
      @bosh_environment = bosh_environment
      @options = {
        interactive: true,
        rebase: false,
        dirty: false
      }.merge(options)

      @bosh_config = Tempfile.new("bosh_config")
      @bosh_output_file = Tempfile.new("bosh_output")
    end

    def create_and_upload_dev_release(release_path, release_name)
      create_and_upload_release(release_path, release_name,
        rebase: @options.fetch(:rebase),
        force: @options.fetch(:dirty),
      )
    end

    def create_and_upload_final_release(release_path, release_name, private_config)
      create_and_upload_release(release_path, release_name,
        final: true,
        private_config: private_config,
        rebase: @options.fetch(:rebase),
      )
    end

    def director_uuid
      run_bosh("target #{bosh_director}", flags: "-n")
      YAML.load_file(@bosh_config.path)["target_uuid"]
    end

    def set_deployment(manifest)
      @logger.log_message "setting deployment to #{manifest}"

      # despite passing -t for the target, this has to be set in the config file
      run_bosh("target #{bosh_director}", flags: "-n")
      run_bosh("deployment #{manifest}", flags: bosh_flags)
    end

    def deploy
      @logger.log_message "DEPLOYING!"

      if @options[:interactive]
        run_bosh("deploy", flags: bosh_flags)
      else
        run_bosh("deploy", pre: "yes yes |", flags: bosh_flags(true))
      end
    end

    private

    def create_and_upload_release(release_path, release_name, options={})
      final = options.fetch(:final, false)
      private_config = options[:private_config]
      rebase = options.fetch(:rebase, false)
      force = options.fetch(:force, false)
      reset_bosh_final_build_stupidity(release_path, FINAL_CONFIG)

      @logger.log_message "setting release name to '#{release_name}'"
      set_release_name(release_path, release_name)

      @logger.log_message "creating dev release"
      create_release(release_path, final: false, force: force)
      create_final_release(force, private_config, release_path) if final

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

    def create_release(release_path, options={})
      flags = []
      flags << "--final" if options[:final]
      flags << "--force" if options[:force]

      create_release_flags = flags.collect { |x| " #{x}" }.join

      run_bosh("create release#{create_release_flags}", pre: "cd #{release_path} &&", flags: bosh_flags)
    end

    def create_final_release(force, private_config, release_path)
      reset_bosh_final_build_stupidity(release_path, FINAL_CONFIG, ".final_builds/")

      if private_config
        @logger.log_message "configuring blobstore"
        copy_private_config(release_path, private_config)
      end

      @logger.log_message "creating final release"
      create_release(release_path, final: true, force: force)
    end

    def upload_release(release_path, rebase)
      upload_flags = %w(--skip-if-exists)
      upload_flags << '--rebase' if rebase
      begin
        run_bosh("upload release #{upload_flags.join(' ')} | tee #{bosh_output_file.path}", pre: "cd #{release_path} &&", flags: bosh_flags)
      rescue CommandRunner::CommandFailed => e
        contents = File.read(@bosh_output_file.path)
        raise e unless contents.match(/Rebase is attempted without any job or package changes/)
      end
    end

    def run_bosh(command, options = {}, &blk)
      command = "set -o pipefail && #{options[:pre]} bosh #{options[:flags]} #{command}"
      environment = {environment: { "BOSH_CONFIG" => @bosh_config.path }}
      @runner.run!(command, environment, &blk)
    end

    def bosh_flags(interactive = @options[:interactive])
      flags = [
        "-t #{bosh_director}",
        "-u #{@bosh_environment["BOSH_USER"]}",
        "-p #{@bosh_environment["BOSH_PASSWORD"]}",
      ]
      flags << "-n" unless interactive
      flags.join(" ")
    end

    def bosh_director
      @bosh_environment["BOSH_DIRECTOR"]
    end

    def copy_private_config(release_path, source_path)
      @runner.run! "cp #{source_path} #{release_path}/config/private.yml"
    end
  end
end
