require 'spec_helper'
require 'cf_deployer/deploy_environment'

module CfDeployer
  describe DeployEnvironment do
    let(:director_uuid) { 'FEED-DEAD-BEEF' }
    let(:is_final_release) { false }
    let(:rebase) { false }
    let(:infrastructure) { 'aws' }
    let(:promote_branch) { nil }
    let(:bosh_environment) { {} }
    let(:release_repo) { double(:release_repo).as_null_object }
    let(:manifest_generator) { double(:manifest_generator, overrides: {}) }
    let(:bosh) { double(:bosh, director_uuid: director_uuid) }
    let(:manifest_domain) { nil }

    let(:options) do
      double(:options,
             rebase: rebase,
             repos_path: '/path/to/repos',
             deployments_repo: 'fake-deployments_repo',
             release_repo: 'fake-release_repo',
             release_name: 'fake-name',
             release_ref: 'fake-ref',
             deployment_name: 'deployment-name',
             interactive: false,
             infrastructure: infrastructure,
             final_release: is_final_release,
             install_tokens: true,
             promote_branch: promote_branch,
             dirty: false,
             dry_run: true,
             manifest_domain: manifest_domain
      ).as_null_object
    end

    let(:logger) { double(:logger) }
    let(:runner) { double(:runner).as_null_object }

    subject(:deploy_environment) do
      DeployEnvironment.new(options, logger)
    end

    before do
      Repo.stub(:new).and_return(double(:repo).as_null_object)
      Deployment.stub(:new).and_return(double(:deployment, :bosh_environment => bosh_environment))

      allow(ReleaseRepo).to receive(:new).and_return(release_repo)
      allow(Bosh).to receive(:new).and_return(bosh)
      allow(ReleaseManifestGenerator).to receive(:new).and_return(manifest_generator)
      allow(DevDeploymentStrategy).to receive(:new).and_return(double(:deployment_strategy).as_null_object)
      allow(CommandRunner).to receive(:new).and_return(runner)
    end

    specify CommandRunner do
      deploy_environment.prepare
      expect(CommandRunner).to have_received(:new).with(logger, options.dry_run)
    end

    specify Repo do
      deploy_environment.prepare
      expect(Repo).to have_received(:new).with(logger, runner, '/path/to/repos', 'fake-deployments_repo', 'origin/master')
    end

    specify ReleaseRepo do
      deploy_environment.prepare
      expect(ReleaseRepo).to have_received(:new).with(logger, runner, '/path/to/repos', 'fake-release_repo', 'fake-ref')
    end

    context 'when the rebase option is false' do
      specify Bosh do
        deploy_environment.prepare
        expect(Bosh).to have_received(:new)
                        .with(logger, runner, bosh_environment,
                              interactive: false, rebase: rebase, dirty: false, dry_run: true)
      end
    end

    context 'when the rebase option is set to true' do
      let(:rebase) { true }

      specify Bosh do
        deploy_environment.prepare
        expect(Bosh).to have_received(:new)
                        .with(logger, runner, bosh_environment,
                              interactive: false, rebase: rebase, dirty: false, dry_run: true)
      end
    end

    specify ReleaseManifestGenerator do
      deploy_environment.prepare
      expect(ReleaseManifestGenerator).to have_received(:new)
                                          .with(runner, release_repo, infrastructure, 'new_deployment.yml')
    end

    context 'when the final option is true' do
      let(:is_final_release) { true }

      it 'uses final deployment strategy' do
        expect(FinalDeploymentStrategy).to receive(:new).and_return(double(:final_deployment_strategy))
        described_class.new(options, logger).prepare
      end
    end

    describe 'manifest generator overrides' do
      context 'when the infrastructure is warden' do
        let(:infrastructure) { 'warden' }

        it 'overrides the director_uuid in the manifest' do
          deploy_environment.prepare
          expected_overrides = {
            'director_uuid' => director_uuid
          }
          expect(manifest_generator.overrides).to eq(expected_overrides)
        end
      end

      context 'when the infrastructure is not warden' do
        it 'does not apply any overrides' do
          deploy_environment.prepare
          expect(manifest_generator.overrides).to eq({})
        end
      end

      context 'when the manifest domain was specified at the CLI' do
        let(:manifest_domain) { 'example.com' }
        it 'overrides the domain in the manifest' do
          deploy_environment.prepare
          expected_overrides = {
            'properties' => {
              'domain' => manifest_domain
            }
          }
          expect(manifest_generator.overrides).to eq(expected_overrides)
        end
      end

      context 'when the manifest domain was not specified at the CLI' do
        it 'does not apply the domain override' do
          deploy_environment.prepare
          expect(manifest_generator.overrides).to eq({})
        end
      end
    end
  end
end
