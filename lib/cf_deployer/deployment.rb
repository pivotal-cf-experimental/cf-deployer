require "fileutils"
require "tempfile"

require "cf_deployer/command_runner"
require "cf_deployer/release_repo"

module CfDeployer
  class Deployment
    def initialize(deployment_directory)
      @deployment_directory = deployment_directory
    end

    def stub_files
      [ deployment_file("cf-stub.yml"),
        deployment_file("cf-aws-stub.yml"),
        deployment_file("cf-shared-secrets.yml"),
      ].compact
    end

    def bosh_environment
      sanitized_bosh_environment
    end

    private

    def deployment_file(filename)
      path = File.expand_path(File.join(@deployment_directory, filename))

      if File.exists?(path)
        path
      end
    end

    def sanitized_bosh_environment
      bosh_environment = deployment_file("bosh_environment")
      raise "No bosh_environment file" unless bosh_environment

      env = IO.popen ["bash", "-c", "source #{bosh_environment} && env", unsetenv_others: true]

      bosh_env = {}

      env.each_line do |line|
        name, val = line.split("=", 2)
        next if %w[PWD SHLVL _].include?(name)

        bosh_env[name] = val[0..-2]
      end

      bosh_env
    end

    def parse_env_output(output)
      env = {}

      output.split("\n").each do |line|
        name, val = line.split("=", 2)
        next if %w[PWD SHLVL _].include?(name)

        env[name] = val
      end

      env
    end
  end
end