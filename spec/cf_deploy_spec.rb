require "spec_helper"
require "cf_deployer/cf_deploy"

module CfDeployer
  describe CfDeploy do
    describe "#deploy" do
      let(:deployment_strategy) { double(:strategy).as_null_object }
      let(:bosh_environment) { {} }
      let(:deployment) { double(Deployment, :bosh_environment => bosh_environment) }
      let(:manifest_generator) { double(ReleaseManifestGenerator) }
      let(:runner) { double(CommandRunner) }
      let(:promote_branch) { nil }

      let(:env) {
        double(:environment,
               strategy: deployment_strategy,
               deployment: deployment,
               manifest_generator: manifest_generator,
               runner: runner,
               options: double(:options,
                               deployment_name: "anchors aweigh",
                               install_tokens: true,
                               promote_branch: promote_branch
               )
        )
      }

      subject(:cf_deploy) do
        described_class.new(env, double(:logger).as_null_object)
      end

      let(:release_repo) { double(ReleaseRepo, :sync! => nil) }

      context "when the bosh environment specifies the datadog environment variables" do
        let(:fake_datadog_emitter) do
          double(
            pre_deploy: nil,
            post_deploy: nil,
          )
        end

        let(:bosh_environment) do
          {"DATADOG_API_KEY" => "api", "DATADOG_APPLICATION_KEY" => "application"}
        end

        before do
          DatadogEmitter.stub(:new).and_return(fake_datadog_emitter)
        end

        it "installs the datadog hooks" do
          cf_deploy.create_final_release_and_deploy!
          expect(env.strategy).to have_received(:install_hook).with(fake_datadog_emitter)
        end
      end

      context "when the promote_branch option is specified" do
        let(:promote_branch) { "cool_branch" }

        it "promotes to the branch" do
          cf_deploy.create_final_release_and_deploy!
          expect(deployment_strategy).to have_received(:promote_to!).with(promote_branch)
        end
      end

      specify TokenInstaller do
        TokenInstaller.stub(:new)
        cf_deploy.create_final_release_and_deploy!
        expect(TokenInstaller).to have_received(:new).with(manifest_generator, runner)
      end
    end
  end
end
