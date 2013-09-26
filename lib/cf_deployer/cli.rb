require 'optparse'

module CfDeployer
  class Cli
    VALID_INFRASTRUCTURES = %w[aws warden vsphere].freeze

    OPTIONS = {
      release_name: "cf-release",
      deploy_branch: "master",
      deploy_env: nil,
      promote_branch: nil,
      tag: nil,
      tokens: true,
      interactive: true,
      repos_path: "./repos",
      deployments_repo: "deployments-aws",
      infrastructure: "aws",
      final_release: false,
    }

    class Options < Struct.new(*OPTIONS.keys)
      def tokens?
        !!tokens
      end

      def interactive?
        !!interactive
      end
    end

    def initialize(args)
      @args = args
      @options = Options.new

      OPTIONS.each do |opt, default|
        @options.send(:"#{opt}=", default)
      end
    end

    def parse!
      parser.parse!(@args)
      @options
    end

    def validate!
      if @options.deploy_env.nil?
        fail "deploy_env is required"
      end

      unless VALID_INFRASTRUCTURES.include?(@options.infrastructure)
        fail "infrastructure must be one of #{VALID_INFRASTRUCTURES.inspect}"
      end
    end

    private

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Example: ci_deploy.rb -d tabasco"

        opts.on(
          "-r RELEASE_NAME",
          "--release RELEASE_NAME",
          %Q{Release repositories to deploy (i.e. "cf-release" or "cf-services-release"). DEFAULT: #{@options.release_name}}
        ) do |release_name|
          @options.release_name = release_name
        end

        opts.on(
          "-b DEPLOY_BRANCH",
          "--branch DEPLOY_BRANCH",
          %Q{Release repository branch to deploy (i.e. "master", "a1", "rc"). DEFAULT: #{@options.deploy_branch}}
        ) do |deploy_branch|
          @options.deploy_branch = deploy_branch
        end

        opts.on(
          "-d DEPLOY_ENV",
          "--deploy DEPLOY_ENV",
          %Q{Name of environment to deploy to (i.e. "tabasco", "a1")}
        ) do |deploy_env|
          @options.deploy_env = deploy_env
        end

        opts.on(
          "-p PROMOTE_BRANCH",
          "--promote PROMOTE_BRANCH",
          %Q{Branch to promote to after a successful deploy (i.e. "release-candidate", "deployed-to-prod")}
        ) do |promote_branch|
          @options.promote_branch = promote_branch
        end

        opts.on(
          "--[no-]tokens",
          %Q{Adding service tokens DEFAULT true}
        ) do |tokens|
          @options.tokens = tokens
        end

        opts.on(
          "-n",
          "--non-interactive",
          %Q{Run bosh interactively. DEFAULT: #{@options.interactive}}
        ) do |interactive|
          @options.interactive = !interactive
        end

        opts.on(
          "--repos REPOS",
          %Q{Where to place release/deployment repositories. DEFAULT: #{@options.repos_path}}
        ) do |repos_path|
          @options.repos_path = repos_path
        end

        opts.on(
          "--deployments-repo DEPLOYMENTS_REPO",
          %Q{Which deployments repository to use. DEFAULT: #{@options.deployments_repo}}
        ) do |deployments_repo|
          @options.deployments_repo = deployments_repo
        end

        opts.on(
          "-i INFRASTRUCTURE",
          "--infrastructure INFRASTRUCTURE",
          %Q{Which infrastructure to deploy. DEFAULT: #{@options.infrastructure}}
        ) do |infrastructure|
          @options.infrastructure = infrastructure
        end

        opts.on(
          "--final",
          %Q{Create upload and deploy a final release instead of a dev release. DEFAULT: #{@options.final_release}}
        ) do |final_release|
          @options.final_release = final_release
        end
      end
    end
  end
end
