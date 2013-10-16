require "spec_helper"
require "cf_deployer/cf_deploy"

module CfDeployer
  describe CfDeploy do
    describe "#deploy" do
      subject(:cf_deploy) do
        described_class.new(
          double(:options,
            rebase: rebase,

            repos_path: nil,
            deployments_repo: nil,
            release_repo: nil,
            release_name: 'release-name',
            release_ref: nil,
            deployment_name: 'deployment-name',
            interactive: false,
            infrastructure: 'aws',
            final_release: true,
            install_tokens: false,
            promote_branch: nil
          )
        )
      end
      let(:null_object) { double(:null_object).as_null_object }
      let(:logger) { null_object }
      let(:runner) { null_object }

      before do
        allow(Repo).to receive(:new).and_return(null_object)
        allow(ReleaseRepo).to receive(:new).and_return(null_object)
        allow(Deployment).to receive(:new).and_return(null_object)
        allow(Bosh).to receive(:new).and_return(null_object)
        allow(ReleaseManifestGenerator).to receive(:new).and_return(null_object)
        allow(FinalDeploymentStrategy).to receive(:new).and_return(null_object)
        allow(DatadogEmitter).to receive(:new).and_return(null_object)
      end

      context "when the rebase option is false" do
        let(:rebase) { false }

        it "passes rebase=false into the Bosh instance" do
          cf_deploy.deploy(logger, runner)

          expect(Bosh).to have_received(:new).with(anything, anything, anything,
            hash_including(rebase: false)
          )
        end
      end

      context "when the rebase option is set to true" do
        let(:rebase) { true }

        it "passes the rebase option into the Bosh instance" do
          cf_deploy.deploy(logger, runner)

          expect(Bosh).to have_received(:new).with(anything, anything, anything,
            hash_including(rebase: true)
          )
        end
      end
    end
  end
end