require 'optparse'

module CfDeployer
  class Cli
    VALID_INFRASTRUCTURES = %w[aws warden vsphere].freeze

    OPTIONS = {
      release_name: nil,

      release_repo: nil,
      deployments_repo: nil,

      release_ref: nil,
      promote_branch: nil,

      infrastructure: nil,

      deployment_name: nil,

      final_release: false,
      interactive: true,
      repos_path: "./repos",
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
      if @options.release_name.nil?
        fail "--release-name is required"
      end

      if @options.release_repo.nil?
        fail "--release-repo is required"
      end

      if @options.deployments_repo.nil?
        fail "--deployments-repo is required"
      end

      if @options.release_ref.nil?
        fail "--release-ref is required"
      end

      if @options.deployment_name.nil?
        fail "--deployment-name is required"
      end

      unless VALID_INFRASTRUCTURES.include?(@options.infrastructure)
        fail "--infrastructure must be one of #{VALID_INFRASTRUCTURES.inspect}"
      end
    end

    private

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Example: ci_deploy.rb -d tabasco"

        opts.on(
          "--release-repo RELEASE_REPO_URI", "URI to the release repository to deploy."
        ) do |release_repo|
          @options.release_repo = release_repo
        end

        opts.on(
          "--release-name RELEASE_NAME", "Name of the BOSH release to create."
        ) do |release_name|
          @options.release_name = release_name
        end

        opts.on(
          "--release-ref RELEASE_REF", "Git ref to deploy from the release repository (e.g. master, a1, v144)."
        ) do |release_ref|
          @options.release_ref = release_ref
        end

        opts.on(
          "--deployment-name DEPLOYMENT_NAME", "Name of environment to deploy to (e.g. tabasco, a1)."
        ) do |deployment_name|
          @options.deployment_name = deployment_name
        end

        opts.on(
          "--promote-to BRANCH", "Branch to push to after deploying (e.g. release-candidate)."
        ) do |promote_branch|
          @options.promote_branch = promote_branch
        end

        opts.on(
          "--deployments-repo DEPLOYMENTS_REPO_URI", "URI to the repository containing the deployment."
        ) do |deployments_repo|
          @options.deployments_repo = deployments_repo
        end

        opts.on(
          "--infrastructure INFRASTRUCTURE", "Which infrastructure to deploy."
        ) do |infrastructure|
          @options.infrastructure = infrastructure
        end

        opts.on(
          "--non-interactive", "Run BOSH non-interactively. DEFAULT: #{@options.interactive}"
        ) do |interactive|
          @options.interactive = !interactive
        end

        opts.on(
          "--clone-to REPOS_PATH", "Where to place release/deployment repositories. DEFAULT: #{@options.repos_path}"
        ) do |repos_path|
          @options.repos_path = repos_path
        end

        opts.on(
          "--final", "Create upload and deploy a final release instead of a dev release. DEFAULT: #{@options.final_release}"
        ) do |final_release|
          @options.final_release = final_release
        end
      end
    end
  end
end
