require 'fileutils'
require 'tempfile'

require 'cf_deployer/release_repo'
require 'yaml'

module CfDeployer
  class Deployment
    def initialize(deployment_directory)
      @deployment_directory = deployment_directory
    end

    def stub_files
      [ deployment_file('cf-stub.yml'),
        deployment_file('cf-aws-stub.yml'),
        deployment_file('cf-shared-secrets.yml'),
      ].compact
    end

    def bosh_environment
      sanitized_bosh_environment
    end

    def private_config
      deployment_file(File.join('config', 'private.yml'))
    end

    def director_uuid_stub_file(director_uuid)
      @director_uuid_stub ||= begin
        director_uuid_file = Tempfile.new('director-uuid')
        stub = { 'director_uuid' => director_uuid }
        File.open(director_uuid_file, 'w') { |f| f.write(YAML.dump(stub)) }
        director_uuid_file.path
      end
    end

    private

    def deployment_file(filename)
      path = File.expand_path(File.join(@deployment_directory, filename))

      if File.exists?(path)
        path
      end
    end

    def sanitized_bosh_environment
      bosh_environment = deployment_file('bosh_environment')
      raise 'No bosh_environment file' unless bosh_environment

      command = "source #{bosh_environment} && env"

      env = ShellOut.with_clean_env(command)

      bosh_env = {}

      env.each_line do |line|
        name, val = line.split('=', 2)
        next if %w[PWD SHLVL _].include?(name)

        bosh_env[name] = val[0..-2]
      end

      bosh_env
    end

    def parse_env_output(output)
      env = {}

      output.split("\n").each do |line|
        name, val = line.split('=', 2)
        next if %w[PWD SHLVL _].include?(name)

        env[name] = val
      end

      env
    end
  end
end
