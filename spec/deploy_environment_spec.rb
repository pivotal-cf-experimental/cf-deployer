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

    def make_new_deploy_environment
      DeployEnvironment.new(options, logger)
    end

    before do
      Repo.stub(:new).and_return(double(:repo).as_null_object)
      Deployment.stub(:new).and_return(double(:deployment, :bosh_environment => bosh_environment))

      allow(ReleaseRepo).to receive(:new).and_return(release_repo)
      allow(Bosh).to receive(:new).and_return(bosh)
      allow(bosh).to receive(:show_version).with(no_args)
      allow(ReleaseManifestGenerator).to receive(:new).and_return(manifest_generator)
      allow(DevDeploymentStrategy).to receive(:new).and_return(double(:deployment_strategy).as_null_object)
      allow(CommandRunner).to receive(:new).and_return(runner)
    end

    specify CommandRunner do
      make_new_deploy_environment
      expect(CommandRunner).to have_received(:new).with(logger, options.dry_run)
    end

    specify Repo do
      make_new_deploy_environment
      expect(Repo).to have_received(:new).with(logger, runner, '/path/to/repos', 'fake-deployments_repo', 'master')
    end

    specify ReleaseRepo do
      make_new_deploy_environment
      expect(ReleaseRepo).to have_received(:new).with(logger, runner, '/path/to/repos', 'fake-release_repo', 'fake-ref')
    end

    context 'when the rebase option is false' do
      specify Bosh do
        make_new_deploy_environment
        expect(Bosh).to have_received(:new)
                        .with(logger, runner, bosh_environment,
                              interactive: false, rebase: rebase, dirty: false, dry_run: true)
      end
    end

    context 'when the rebase option is set to true' do
      let(:rebase) { true }

      specify Bosh do
        make_new_deploy_environment
        expect(Bosh).to have_received(:new)
                        .with(logger, runner, bosh_environment,
                              interactive: false, rebase: rebase, dirty: false, dry_run: true)
      end
    end

    specify ReleaseManifestGenerator do
      make_new_deploy_environment
      expect(ReleaseManifestGenerator).to have_received(:new)
                                          .with(runner, release_repo, infrastructure, 'new_deployment.yml')
    end

    context 'when the final option is true' do
      let(:is_final_release) { true }

      it 'uses final deployment strategy' do
        expect(FinalDeploymentStrategy).to receive(:new).and_return(double(:final_deployment_strategy))
        make_new_deploy_environment
      end
    end

    it 'shows the bosh version when a deploy environment is created' do
      expect(bosh).to receive(:show_version).with(no_args)
      make_new_deploy_environment
    end

    describe 'manifest generator overrides' do
      context 'when the infrastructure is warden' do
        let(:infrastructure) { 'warden' }

        it 'overrides the director_uuid in the manifest' do
          make_new_deploy_environment
          expected_overrides = {
            'director_uuid' => director_uuid
          }
          expect(manifest_generator.overrides).to eq(expected_overrides)
        end
      end

      context 'when the infrastructure is not warden' do
        it 'does not apply any overrides' do
          make_new_deploy_environment
          expect(manifest_generator.overrides).to eq({})
        end
      end

      context 'when the manifest domain was specified at the CLI' do
        let(:manifest_domain) { 'example.com' }
        it 'overrides the domain in the manifest' do
          make_new_deploy_environment
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
          make_new_deploy_environment
          expect(manifest_generator.overrides).to eq({})
        end
      end
    end
  end
end
