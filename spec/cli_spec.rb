require 'spec_helper'
require 'cf_deployer/cli'

describe CfDeployer::Cli do
  subject(:cli) { described_class.new(args) }
  let(:args) do
    %w(
        --release-repo=my_release_repo
        --release-name=my_release_name
        --deployments-repo=my_deployments_repo
        --deployment-name=my_deployment_name
        --infrastructure=aws
        --release-ref=master
      )
  end

  describe "required options" do
    it "successfully validates when all the required args are present" do
      expect(cli).to validate_successfully
    end

    it "fails when release repo is not specified" do
      args.delete_if { |s| s.match /--release-repo/ }
      expect(cli).to fail_validation(/at least one --release-repo is required/)
    end

    it "fails when release name is not specified" do
      args.delete_if { |s| s.match /--release-name/ }
      expect(cli).to fail_validation(/at least one --release-name is required/)
    end

    it "fails when the number of release repos does not match the number of release names" do
      args << "--release-name=my_other_release_name"
      expect(cli).to fail_validation(/missing --release-repo and --release-name pair/)
    end

    it "fails when deployments repo is not specified" do
      args.delete_if { |s| s.match /--deployments-repo/ }
      expect(cli).to fail_validation(/--deployments-repo is required/)
    end

    it "fails when deployment name is not specified" do
      args.delete_if { |s| s.match /--deployment-name/ }
      expect(cli).to fail_validation(/--deployment-name is required/)
    end

    it "fails when the infrastructure is not recognized" do
      args.delete_if { |s| s.match /--infrastructure/ }
      args << "--infrastructure=steel"
      expect(cli).to fail_validation(/--infrastructure must be one of/)
    end

    it "succeeds if --dirty is used instead of --release-ref" do
      args.delete_if { |s| s.match /--release-ref/ }
      args << "--dirty"
      expect(cli).to validate_successfully
    end

    it "fails if both --release-ref and --dirty are missing" do
      args.delete_if { |s| s.match /--release-ref/ }
      expect(cli).to fail_validation(/--release-ref or --dirty is required/)
    end
  end

  describe "parsed options" do
    it "exposes options matching the command line arguments" do
      expect(cli).to validate_successfully
      opts = cli.options
      expect(opts.release_repos).to eq(%w(my_release_repo))
      expect(opts.release_names).to eq(%w(my_release_name))
      expect(opts.release_refs).to eq(%w(master))

      expect(opts.deployments_repo).to eq("my_deployments_repo")
      expect(opts.deployment_name).to eq("my_deployment_name")
      expect(opts.infrastructure).to eq("aws")
    end

    it "exposes default options for non-required command line arguments" do
      expect(cli).to validate_successfully
      opts = cli.options
      expect(opts.repos_path).to eq("./repos")
      expect(opts.dirty).to eq(false)
      expect(opts.promote_branch).to be_nil
      expect(opts.final_release).to eq(false)
      expect(opts.rebase).to eq(false)
      expect(opts.interactive).to eq(true)
      expect(opts.install_tokens).to eq(false)
      expect(opts.dry_run).to eq(false)
      expect(opts.manifest_domain).to be_nil
    end

    describe "overridden, non-required options" do
      it "exposes overridden --repos" do
        args << "--repos=my_repos_path"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.repos_path).to eq("my_repos_path")
      end

      it "exposes overridden --dirty" do
        args << "--dirty"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.dirty).to eq(true)
      end

      it "exposes overridden --promote-to" do
        args << "--promote-to=my_promote_branch"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.promote_branch).to eq("my_promote_branch")
      end

      it "exposes overridden --final" do
        args << "--final"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.final_release).to eq(true)
      end

      it "exposes overridden --rebase" do
        args << "--rebase"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.rebase).to eq(true)
      end

      it "exposes overridden --non-interactive" do
        args << "--non-interactive"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.interactive).to eq(false)
      end

      it "exposes overridden --install-tokens" do
        args << "--install-tokens"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.install_tokens).to eq(true)
      end

      it "exposes overridden --dry-run" do
        args << "--dry-run"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.dry_run).to eq(true)
      end

      it "exposes overridden --manifest-domain" do
        args << "--manifest-domain=example.com"

        expect(cli).to validate_successfully
        opts = cli.options
        expect(opts.manifest_domain).to eq("example.com")
      end
    end
  end

  matcher(:validate_successfully) do
    match do |cli|
      cli.parse!
      cli.validate!
      true
    end
  end

  matcher(:fail_validation) do |message|
    match do |cli|
      cli.parse!
      begin
        cli.validate!
      rescue CfDeployer::Cli::OptionError => e
        @err = e
      end

      @err.to_s.match(message)
    end

    failure_message_for_should do |cli|
      if @err.nil?
        "Expected failure message matching #{message}, but got nothing"
      else
        "Expected failure message matching #{message}, got:\n#{@err.to_s}"
      end
    end
  end
end
