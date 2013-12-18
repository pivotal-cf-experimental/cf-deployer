require "spec_helper"
require "cf_deployer/cf_deploy"

# TODO: can we do this with fakes instead?
#
# this is hella stubby and is just a puzzle when actually changing something

module CfDeployer
  describe CfDeploy do
    describe "#deploy" do
      subject(:cf_deploy) do
        described_class.new(options, logger)
      end

      let(:null_object) { double(:null_object).as_null_object }

      let(:release_names) do
        release_names = double(:release_names)
        release_names.stub(:zip).and_yield('fake-name', 'fake-release_repo', 'fake-ref')
        release_names
      end

      let(:logger) { null_object }
      let(:runner) { double(CommandRunner) }
      let(:deployment ) { double(Deployment, :bosh_environment => "bosh-environment") }
      let(:manifest_generator) { double(ReleaseManifestGenerator) }
      let(:release_repo) { double(ReleaseRepo, :sync! => nil) }
      let(:is_final_release) { false }
      let(:rebase) { false }
      let(:infrastructure) { "aws" }
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
               promote_branch: nil,
               dirty: false,
        ).as_null_object
      end

      before do
        allow(Repo).to receive(:new).and_return(null_object)
        allow(ReleaseRepo).to receive(:new).and_return(release_repo)
        allow(Deployment).to receive(:new).and_return(deployment)
        allow(Bosh).to receive(:new).and_return(null_object)
        allow(ReleaseManifestGenerator).to receive(:new).and_return(manifest_generator)
        allow(DevDeploymentStrategy).to receive(:new).and_return(null_object)
        allow(DatadogEmitter).to receive(:new).and_return(null_object)
        allow(TokenInstaller).to receive(:new).and_return(null_object)
      end

      context "instantiation of collaborators" do
        specify Repo do
          cf_deploy.deploy(runner)

          expect(Repo).to have_received(:new).with(logger, runner, "/path/to/repos", "fake-deployments_repo", "origin/master")
        end

        specify ReleaseRepo do
          cf_deploy.deploy(runner)

          expect(ReleaseRepo).to have_received(:new).with(logger, runner, "/path/to/repos", "fake-release_repo", "fake-ref")
        end

        specify Bosh do
          cf_deploy.deploy(runner)

          expect(Bosh).to have_received(:new)
                          .with(logger, runner, "bosh-environment", interactive: false, rebase: rebase, dirty: false)
        end

        specify ReleaseManifestGenerator do
          cf_deploy.deploy(runner)

          expect(ReleaseManifestGenerator).to have_received(:new)
                                              .with(runner, release_repo, infrastructure, "new_deployment.yml")
        end

        specify TokenInstaller do
          cf_deploy.deploy(runner)

          expect(TokenInstaller).to have_received(:new)
                                              .with(logger, manifest_generator, runner)
        end
      end

      context "when the rebase option is false" do
        it "passes rebase=false into the Bosh instance" do
          cf_deploy.deploy(runner)

          expect(Bosh).to have_received(:new).with(anything, anything, anything,
            hash_including(rebase: false)
          )
        end
      end

      context "when the rebase option is set to true" do
        let(:rebase) { true }

        it "passes the rebase option into the Bosh instance" do
          cf_deploy.deploy(runner)

          expect(Bosh).to have_received(:new).with(anything, anything, anything,
            hash_including(rebase: true)
          )
        end
      end

      context "when the final option is true" do
        let(:is_final_release) { true }

        it "uses final deployment strategy" do
          expect(FinalDeploymentStrategy).to receive(:new).and_return(null_object)
          cf_deploy.deploy(runner)
        end
      end

      context "when the infrastructure is warden" do
        let(:infrastructure) { "warden" }

        it "uses warden deployment strategy" do
          expect(WardenDeploymentStrategy).to receive(:new).and_return(null_object)
          cf_deploy.deploy(runner)
        end
      end
    end
  end
end
