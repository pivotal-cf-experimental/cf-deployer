require 'spec_helper'
require 'cf_deployer/options_parser'

describe CfDeployer::OptionsParser do
  subject(:options_parser) { described_class.new(args) }
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

  describe 'required options' do
    it 'successfully validates when all the required args are present' do
      expect(options_parser).to validate_successfully
    end

    it 'fails when release repo is not specified' do
      args.delete_if { |s| s.match /--release-repo/ }
      expect(options_parser).to fail_validation(/exactly one --release-repo is required/)
    end

    it 'fails when release name is not specified' do
      args.delete_if { |s| s.match /--release-name/ }
      expect(options_parser).to fail_validation(/exactly one --release-name is required/)
    end

    it 'fails when deployments repo is not specified' do
      args.delete_if { |s| s.match /--deployments-repo/ }
      expect(options_parser).to fail_validation(/--deployments-repo is required/)
    end

    it 'fails when deployment name is not specified' do
      args.delete_if { |s| s.match /--deployment-name/ }
      expect(options_parser).to fail_validation(/--deployment-name is required/)
    end

    it 'fails when the infrastructure is not recognized' do
      args.delete_if { |s| s.match /--infrastructure/ }
      args << '--infrastructure=steel'
      expect(options_parser).to fail_validation(/--infrastructure must be one of/)
    end

    it 'succeeds if --dirty is used instead of --release-ref' do
      args.delete_if { |s| s.match /--release-ref/ }
      args << '--dirty'
      expect(options_parser).to validate_successfully
    end

    it 'fails if both --release-ref and --dirty are missing' do
      args.delete_if { |s| s.match /--release-ref/ }
      expect(options_parser).to fail_validation(/--release-ref or --dirty is required/)
    end

    it 'fails if both --local-blob-cache-dir and --dirty are specified' do
      args << '--dirty'
      args << '--local-blob-cache-dir=my_dir'
      expect(options_parser).to fail_validation(/can not specify --local-blob-cache-dir if --dirty is specified/)
    end
  end

  describe 'parsed options' do
    it 'exposes options matching the command line arguments' do
      expect(options_parser).to validate_successfully
      opts = options_parser.options
      expect(opts.release_repo).to eq('my_release_repo')
      expect(opts.release_name).to eq('my_release_name')
      expect(opts.release_ref).to eq('master')

      expect(opts.deployments_repo).to eq('my_deployments_repo')
      expect(opts.deployment_name).to eq('my_deployment_name')
      expect(opts.infrastructure).to eq('aws')
    end

    it 'exposes default options for non-required command line arguments' do
      expect(options_parser).to validate_successfully
      opts = options_parser.options
      expect(opts.repos_path).to eq('./repos')
      expect(opts.dirty).to eq(false)
      expect(opts.promote_branch).to be_nil
      expect(opts.push_branch).to be_nil
      expect(opts.final_release).to eq(false)
      expect(opts.rebase).to eq(false)
      expect(opts.interactive).to eq(true)
      expect(opts.install_tokens).to eq(false)
      expect(opts.dry_run).to eq(false)
      expect(opts.manifest_domain).to be_nil
      expect(opts.local_blob_cache_dir).to be_nil
    end

    describe 'overridden, non-required options' do
      it 'exposes overridden --repos' do
        args << '--repos=my_repos_path'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.repos_path).to eq('my_repos_path')
      end

      it 'exposes overridden --dirty' do
        args << '--dirty'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.dirty).to eq(true)
      end

      it 'exposes overridden --local-blob-cache-dir' do
        args << '--local-blob-cache-dir=my_dir'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.local_blob_cache_dir).to eq("my_dir")
      end

      it 'exposes overridden --promote-to' do
        args << '--promote-to=my_promote_branch'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.promote_branch).to eq('my_promote_branch')
      end

      it 'exposes overridden --push-to' do
        args << '--push-to=the_best_branch'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.push_branch).to eq('the_best_branch')
      end

      it 'exposes overridden --final' do
        args << '--final'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.final_release).to eq(true)
      end

      it 'exposes overridden --rebase' do
        args << '--rebase'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.rebase).to eq(true)
      end

      it 'exposes overridden --non-interactive' do
        args << '--non-interactive'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.interactive).to eq(false)
      end

      it 'exposes overridden --install-tokens' do
        args << '--install-tokens'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.install_tokens).to eq(true)
      end

      it 'exposes overridden --dry-run' do
        args << '--dry-run'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.dry_run).to eq(true)
      end

      it 'exposes overridden --manifest-domain' do
        args << '--manifest-domain=example.com'

        expect(options_parser).to validate_successfully
        opts = options_parser.options
        expect(opts.manifest_domain).to eq('example.com')
      end
    end
  end
end
