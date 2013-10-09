require "thread"

module CanaryBreeder
  ERLANG_BUILDPACK="https://github.com/archaelus/heroku-buildpack-erlang.git"
  GO_BUILDPACK="git://github.com/vito/heroku-buildpack-go.git"

  class Breeder
    def initialize(options)
      @options = options
    end

    def breed(logger, runner)
      logger.log_message "targeting and logging in"
      runner.run! "go-cf api #{@options.target}"
      runner.run! "go-cf login '#{@options.username}' '#{@options.password}'"
      runner.run! "go-cf target -o pivotal -s coal-mine"

      logger.log_message "breeding canaries"

      push_zero_downtime_canary(logger, runner)
      push_aviary(logger, runner)
      push_cpu_canary(logger, runner)
      push_disk_canary(logger, runner)
      push_memory_canary(logger, runner)
      push_network_canary(logger, runner)

      logger.log_message "TWEET TWEET"
    end

    private

    def push_zero_downtime_canary(logger, runner)
      number_of_canaries = @options.number_of_zero_downtime_apps

      logger.log_message "pushing #{number_of_canaries} zero-downtime canaries"

      number_of_canaries.times do |i|
        push_app(logger, runner, "zero-downtime-canary#{i + 1}", { PATH: "/app/otp/bin:bin:/usr/bin:/bin" },
          buildpack: ERLANG_BUILDPACK,
          directory_name: "zero-downtime")
      end
    end

    def push_aviary(logger, runner)
      env = {
        TARGET: @options.target,
        USERNAME: @options.username,
        PASSWORD: @options.password,
        DOMAIN: @options.app_domain,
        NUM_INSTANCES: @options.number_of_instances_canary_instances
      }

      push_app(logger, runner, "aviary", env)
    end

    def push_cpu_canary(logger, runner)
      push_app(logger, runner, "cpu", {}, memory: 512)
    end

    def push_disk_canary(logger, runner)
      push_app(logger, runner, "disk", { SPACE: "768" }, memory: 512)
    end

    def push_memory_canary(logger, runner)
      push_app(logger, runner, "memory", { MEMORY: "112" })
    end

    def push_network_canary(logger, runner)
      push_app(logger, runner, "network", {}, buildpack: GO_BUILDPACK)
    end

    def push_instances_canary(logger, runner)
      push_app(
        logger, runner, "instances", {},
        instances: @options.number_of_instances_canary_instances,
        path: path)
    end

    def push_app(logger, runner, name, env = {}, options = {})
      directory_name = options.fetch(:directory_name, name)
      instances = options.fetch(:instances, 1)
      memory = options.fetch(:memory, 256)
      buildpack = options.fetch(:buildpack, "")

      logger.log_message "pushing #{name} canary"

      if app_exists?(logger, runner, name)
        logger.log_message "skipping"
        return
      end

      logger.log_message "pushing!"

      runner.run! [
        "go-cf push #{name} --no-start",
        "-p #{canary_path(directory_name)}",
        "-n #{name} -d #{@options.app_domain}",
        "-i #{instances} -m #{memory}",
        "-b '#{buildpack}'"
      ].join(" ")

      env.each do |k, v|
        runner.run! "go-cf set-env #{name} #{k} '#{v}'"
      end
      runner.run! "go-cf start #{name}"
    end

    def canary_path(name)
      "#{@options.canaries_path}/#{name}"
    end

    def app_exists?(logger, runner, name)
      logger.log_message "checking for app #{name}"

      begin
        runner.run! "go-cf app #{name}"
        true
      rescue CfDeployer::CommandRunner::CommandFailed => e
        false
      end
    end
  end
end