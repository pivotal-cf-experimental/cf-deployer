require 'optparse'

module CfDeployer
  class Cli
    class Options < Struct.new(:release_name, :deploy_branch, :deploy_env, :promote_branch, :tag, :tokens, :interactive, :repos_path, :deployments_repo)
      def tokens?
        !!tokens
      end

      def interactive?
        !!interactive
      end
    end

    def initialize(args)
      @args = args
      @options = Options.new("cf-release", "master", nil, nil, nil, true, false, "./repos", "deployments-aws")
    end

    def parse!
      parser.parse!(@args)

      fail "deploy_env is required\n\n#{parser}" if @options.deploy_env.nil?

      @options
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
          "-i",
          "--[no-]interactive",
          %Q{Run bosh interactively DEFAULT: #{@options.interactive}}
        ) do |interactive|
          @options.interactive = interactive
        end

        opts.on(
          "--repos",
          %Q{Where to place release/deployment repositories. DEFAULT: #{@options.repos_path}}
        ) do |repos_path|
          @options.repos_path = repos_path
        end

        opts.on(
          "--deployments-repo",
          %Q{Which deployments repository to use. DEFAULT: #{@options.deployments_repo}}
        ) do |deployments_repo|
          @options.deployments_repo = deployments_repo
        end
      end
    end
  end
end