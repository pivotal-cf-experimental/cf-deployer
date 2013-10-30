require 'optparse'

module CfDeployer
  class Cli
    VALID_INFRASTRUCTURES = %w[aws warden vsphere].freeze

    OPTIONS = {
      release_names: [],
      release_repos: [],
      release_refs: [],

      deployment_name: nil,
      deployments_repo: nil,

      repos_path: "./repos",

      dirty: false,

      infrastructure: nil,

      promote_branch: nil,

      final_release: false,
      rebase: false,

      interactive: true,

      install_tokens: false
    }

    class Options < Struct.new(*OPTIONS.keys)
      def tokens?
        !!tokens
      end

      def interactive?
        !!interactive
      end

      def rebase?
        !!rebase
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
      if @options.release_repos.nil?
        fail "at least one --release-repo is required"
      end

      if @options.release_names.empty?
        fail "at least one --release-name is required"
      end

      if @options.release_repos.size != @options.release_names.size
        fail "missing --release-repo and --release-name pair"
      end

      if @options.deployments_repo.nil?
        fail "--deployments-repo is required"
      end

      if @options.deployment_name.nil?
        fail "--deployment-name is required"
      end

      unless VALID_INFRASTRUCTURES.include?(@options.infrastructure)
        fail "--infrastructure must be one of #{VALID_INFRASTRUCTURES.inspect}"
      end

      if !@options.dirty && @options.release_refs.nil?
        fail "--release-ref or --dirty is required"
      end
    end

    private

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Example: ci_deploy.rb -d tabasco"

        opts.on(
          "--release-name RELEASE_NAME", "Name of the BOSH release to create."
        ) do |release_name|
          @options.release_names << release_name
        end

        opts.on(
          "--release-repo RELEASE_REPO_URI", "URI to the release repository to deploy."
        ) do |release_repo|
          @options.release_repos << release_repo
        end

        opts.on(
          "--release-ref RELEASE_REF", "Git ref to deploy from the release repository (e.g. master, a1, v144)."
        ) do |release_ref|
          @options.release_refs << release_ref
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
          "--rebase", "Upload the BOSH release to the director using the --rebase option. DEFAULT: #{@options.rebase}"
        ) do |rebase|
          @options.rebase = !!rebase
        end

        opts.on(
          "--repos REPOS_PATH", "Where to place release/deployment repositories. DEFAULT: #{@options.repos_path}"
        ) do |repos_path|
          @options.repos_path = repos_path
        end

        opts.on(
          "--final", "Create upload and deploy a final release instead of a dev release. DEFAULT: #{@options.final_release}"
        ) do |final_release|
          @options.final_release = final_release
        end

        opts.on(
          "--dirty", "Deploy using whatever state the deployment and release repos are in. DEFAULT: #{@options.dirty}"
        ) do |dirty|
          @options.dirty = dirty
        end

        opts.on(
          "--install-tokens", "Install service auth tokens. DEFAULT: #{@options.install_tokens}"
        ) do |install_tokens|
          @options.install_tokens = install_tokens
        end
      end
    end
  end
end
