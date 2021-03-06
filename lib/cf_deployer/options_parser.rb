require 'optparse'
require 'cf_deployer/version'

module CfDeployer
  class OptionsParser
    class OptionError < RuntimeError; end

    VALID_INFRASTRUCTURES = %w[aws warden vsphere].freeze

    OPTIONS = {
      release_repo: nil,
      release_name: nil,
      release_ref: nil,

      deployments_repo: nil,
      deployment_name: nil,

      infrastructure: nil,

      repos_path: './repos',

      dirty: false,

      promote_branch: nil,
      push_branch: nil,

      final_release: false,
      rebase: false,

      interactive: true,

      install_tokens: false,

      dry_run: false,

      manifest_domain: nil,
      local_blob_cache_dir: nil
    }

    class Options < Struct.new(*OPTIONS.keys); end

    attr_reader :options

    def initialize(args)
      @args = args
      @options = Options.new

      OPTIONS.each do |opt, default|
        val = default.dup rescue default
        @options.send(:"#{opt}=", val)
      end
    end

    def parse!
      parser.parse!(@args)
      @options
    end

    def validate!
      die 'exactly one --release-repo is required' unless @options.release_repo
      die 'can not specify --local-blob-cache-dir if --dirty is specified' if @options.dirty && @options.local_blob_cache_dir
      die 'exactly one --release-name is required' unless @options.release_name
      die '--deployments-repo is required' unless @options.deployments_repo
      die '--deployment-name is required' unless @options.deployment_name
      die "--infrastructure must be one of #{VALID_INFRASTRUCTURES.inspect}" unless VALID_INFRASTRUCTURES.include?(@options.infrastructure)
      die '--release-ref or --dirty is required' unless @options.dirty || @options.release_ref
    end

    private

    def die(msg)
      raise OptionError.new(msg)
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.on(
          '--release-repo RELEASE_REPO_URI', 'URI to the release repository to deploy.'
        ) do |release_repo|
          @options.release_repo = release_repo
        end

        opts.on(
          '--release-name RELEASE_NAME', 'Name of the BOSH release to create.'
        ) do |release_name|
          @options.release_name = release_name
        end

        opts.on(
          '--release-ref RELEASE_REF', 'Git ref to deploy from the release repository (e.g. master, v144).'
        ) do |release_ref|
          @options.release_ref = release_ref
        end

        opts.on(
          '--deployments-repo DEPLOYMENTS_REPO_URI', 'URI to the repository containing the deployment.'
        ) do |deployments_repo|
          @options.deployments_repo = deployments_repo
        end

        opts.on(
          '--deployment-name DEPLOYMENT_NAME', 'Name of environment to deploy to.'
        ) do |deployment_name|
          @options.deployment_name = deployment_name
        end

        opts.on(
          '--infrastructure INFRASTRUCTURE', 'Which infrastructure to deploy.'
        ) do |infrastructure|
          @options.infrastructure = infrastructure
        end

        opts.on(
          '--repos REPOS_PATH', "Where to place release/deployment repositories. DEFAULT: #{@options.repos_path}"
        ) do |repos_path|
          @options.repos_path = repos_path
        end

        opts.on(
          '--dirty', "Deploy using whatever state the deployment and release repos are in. DEFAULT: #{@options.dirty}"
        ) do |dirty|
          @options.dirty = dirty
        end

        opts.on(
            '--local-blob-cache-dir CACHE_DIR', 'Use CACHE_DIR for local blob cache in release repo (.blobs).'
        ) do |local_blob_cache_dir|
          @options.local_blob_cache_dir = local_blob_cache_dir
        end

        opts.on(
          '--promote-to BRANCH', 'Branch to push to after deploying (e.g. release-candidate).'
        ) do |promote_branch|
          @options.promote_branch = promote_branch
        end

        opts.on(
          '--push-to BRANCH', 'Branch to push to after creating a final release (e.g. release-candidate).'
        ) do |push_branch|
          @options.push_branch = push_branch
        end

        opts.on(
          '--final', "Create upload and deploy a final release instead of a dev release. DEFAULT: #{@options.final_release}"
        ) do |final_release|
          @options.final_release = final_release
        end

        opts.on(
          '--rebase', "Upload the BOSH release to the director using the --rebase option. DEFAULT: #{@options.rebase}"
        ) do |rebase|
          @options.rebase = !!rebase
        end

        opts.on(
          '--non-interactive', "Run BOSH non-interactively. DEFAULT: #{@options.interactive}"
        ) do |interactive|
          @options.interactive = !interactive
        end

        opts.on(
          '--install-tokens', "Install service auth tokens. DEFAULT: #{@options.install_tokens}"
        ) do |install_tokens|
          @options.install_tokens = install_tokens
        end

        opts.on(
          '--dry-run', "Only print the commands that would run. DEFAULT: #{@options.dry_run}"
        ) do |dry_run|
          @options.dry_run = dry_run
        end

        opts.on(
          '--manifest-domain DOMAIN', "Override properties.domain in the generated manifest. DEFAULT: #{@options.manifest_domain}"
        ) do |manifest_domain|
          @options.manifest_domain = manifest_domain
        end
      end
      @parser.version = CfDeployer::VERSION
      @parser
    end
  end
end
