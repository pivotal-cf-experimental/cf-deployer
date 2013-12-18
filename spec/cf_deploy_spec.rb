require "spec_helper"
require "cf_deployer/cf_deploy"

# TODO: can we do this with fakes instead?
#
# this is hella stubby and is just a puzzle when actually changing something

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
            infrastructure: infrastructure,
            final_release: is_final_release,
            install_tokens: false,
            promote_branch: nil,
            dirty: false,
          ).as_null_object,
          logger
        )
      end

      let(:null_object) { double(:null_object).as_null_object }
      let(:logger) { null_object }
      let(:runner) { null_object }
      let(:is_final_release) { false }
      let(:rebase) { false }
      let(:infrastructure) { "aws" }

      before do
        allow(Repo).to receive(:new).and_return(null_object)
        allow(ReleaseRepo).to receive(:new).and_return(null_object)
        allow(Deployment).to receive(:new).and_return(null_object)
        allow(Bosh).to receive(:new).and_return(null_object)
        allow(ReleaseManifestGenerator).to receive(:new).and_return(null_object)
        allow(DevDeploymentStrategy).to receive(:new).and_return(null_object)
        allow(DatadogEmitter).to receive(:new).and_return(null_object)
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
