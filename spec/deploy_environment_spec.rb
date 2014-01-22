require "spec_helper"
require "cf_deployer/deploy_environment"

module CfDeployer
  describe DeployEnvironment do
    let(:release_names) do
      release_names = double(:release_names)
      release_names.stub(:zip).and_yield('fake-name', 'fake-release_repo', 'fake-ref')
      release_names
    end

    let(:director_uuid) { "FEED-DEAD-BEEF" }
    let(:is_final_release) { false }
    let(:rebase) { false }
    let(:infrastructure) { "aws" }
    let(:promote_branch) { nil }
    let(:bosh_environment) { {} }
    let(:release_repo) { double(:release_repo).as_null_object }
    let(:manifest_generator) { double(:manifest_generator, overrides: {}) }
    let(:bosh) { double(:bosh, director_uuid: director_uuid) }

    let(:options) do
      double(:options,
             rebase: rebase,
             repos_path: '/path/to/repos',
             deployments_repo: 'fake-deployments_repo',
             release_repo: nil,
             release_names: release_names,
             release_ref: nil,
             deployment_name: 'deployment-name',
             interactive: false,
             infrastructure: infrastructure,
             final_release: is_final_release,
             install_tokens: true,
             promote_branch: promote_branch,
             dirty: false,
             dry_run: true
      ).as_null_object
    end

    let(:logger) { double(:logger) }
    let(:runner) { double(:runner).as_null_object }

    before do
      Repo.stub(:new).and_return(double(:repo).as_null_object)
      Deployment.stub(:new).and_return(double(:deployment, :bosh_environment => bosh_environment))

      allow(ReleaseRepo).to receive(:new).and_return(release_repo)
      allow(Bosh).to receive(:new).and_return(bosh)
      allow(ReleaseManifestGenerator).to receive(:new).and_return(manifest_generator)
      allow(DevDeploymentStrategy).to receive(:new).and_return(double(:deployment_strategy).as_null_object)
      allow(DatadogEmitter).to receive(:new).and_return(double(:datadog_emitter).as_null_object)
      allow(TokenInstaller).to receive(:new).and_return(double(:token_emitter).as_null_object)
      allow(CommandRunner).to receive(:new).and_return(runner)
    end

    specify CommandRunner do
      described_class.new(options, logger)
      expect(CommandRunner).to have_received(:new).with(logger, options.dry_run)
    end

    specify Repo do
      described_class.new(options, logger)
      expect(Repo).to have_received(:new).with(logger, runner, "/path/to/repos", "fake-deployments_repo", "origin/master")
    end

    specify ReleaseRepo do
      described_class.new(options, logger)
      expect(ReleaseRepo).to have_received(:new).with(logger, runner, "/path/to/repos", "fake-release_repo", "fake-ref")
    end

    context "when the rebase option is false" do
      specify Bosh do
        described_class.new(options, logger)
        expect(Bosh).to have_received(:new)
                        .with(logger, runner, bosh_environment,
                              interactive: false, rebase: rebase, dirty: false, dry_run: true)
      end
    end

    context "when the rebase option is set to true" do
      let(:rebase) { true }

      specify Bosh do
        described_class.new(options, logger)
        expect(Bosh).to have_received(:new)
                        .with(logger, runner, bosh_environment,
                              interactive: false, rebase: rebase, dirty: false, dry_run: true)
      end
    end

    specify ReleaseManifestGenerator do
      described_class.new(options, logger)
      expect(ReleaseManifestGenerator).to have_received(:new)
                                          .with(runner, release_repo, infrastructure, "new_deployment.yml")
    end

    context "when the final option is true" do
      let(:is_final_release) { true }

      it "uses final deployment strategy" do
        expect(FinalDeploymentStrategy).to receive(:new).and_return(double(:final_deployment_strategy))
        described_class.new(options, logger)
      end
    end

    describe "manifest generator overrides" do
      context "when the infrastructure is warden" do
        let(:infrastructure) { "warden" }

        it "overrides the director_uuid in the manifest" do
          described_class.new(options, logger)
          expected_overrides = {
            "properties" => {
              "director_uuid" => director_uuid
            }
          }
          expect(manifest_generator.overrides).to eq(expected_overrides)
        end
      end

      context "when the infrastructure is not warden" do
        it "does not apply any overrides" do
          described_class.new(options, logger)
          expect(manifest_generator.overrides).to eq({})
        end
      end
    end
  end
end
