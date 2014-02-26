require "spec_helper"
require "cf_deployer/cf_deploy"
require "cf_deployer/deployment"
require "cf_deployer/command_runner"
require "cf_deployer/release_manifest_generator"

module CfDeployer
  describe CfDeploy do
    let(:bosh_environment) { {} }
    let(:deployment) { double(Deployment, :bosh_environment => bosh_environment) }
    let(:deployment_strategy) { double(:strategy).as_null_object }
    let(:logger) { double(:logger).as_null_object }
    let(:manifest_generator) { double(ReleaseManifestGenerator) }
    let(:promote_branch) { nil }
    let(:runner) { double(CommandRunner) }

    let(:env) {
      double(:environment,
             strategy: deployment_strategy,
             deployment: deployment,
             manifest_generator: manifest_generator,
             runner: runner,
             logger: logger,
             options: double(:options,
                             deployment_name: "anchors aweigh",
                             install_tokens: true,
                             promote_branch: promote_branch
             )
      )
    }

    describe "#initialize" do
      context "when the bosh environment specifies the datadog environment variables" do
        let(:fake_dogapi) { double(Dogapi::Client) }
        let(:bosh_environment) do
          {"DATADOG_API_KEY" => "api", "DATADOG_APPLICATION_KEY" => "application"}
        end

        it "installs the datadog hooks" do
          fake_datadog_emitter = double(DatadogEmitter)
          allow(DatadogEmitter).to receive(:new).and_return(fake_datadog_emitter)

          CfDeploy.new(env)
          expect(env.strategy).to have_received(:install_hook).with(fake_datadog_emitter)
        end

        it "creates the hooks correctly" do
          expect(Dogapi::Client).to receive(:new).with("api", "application").and_return(fake_dogapi)
          expect(DatadogEmitter).to receive(:new).with(logger, fake_dogapi, env.options.deployment_name)

          CfDeploy.new(env)
        end
      end

      describe "token hooks" do
        it "installs the token hooks" do
          fake_token_installer = double(TokenInstaller)
          allow(TokenInstaller).to receive(:new).and_return(fake_token_installer)

          CfDeploy.new(env)
          expect(env.strategy).to have_received(:install_hook).with(fake_token_installer)
        end

        it "creates the hooks correctly" do
          expect(TokenInstaller).to receive(:new).with(manifest_generator, runner)

          CfDeploy.new(env)
        end
      end
    end

    describe "#create_upload_and_deploy_release!" do
      subject(:cf_deploy) do
        described_class.new(env)
      end

      let(:release_repo) { double(ReleaseRepo, :sync! => nil) }

      context "when the promote_branch option is specified" do
        let(:promote_branch) { "cool_branch" }

        it "promotes to the branch" do
          cf_deploy.create_upload_and_deploy_release!
          expect(deployment_strategy).to have_received(:promote_to!).with(promote_branch)
        end
      end
    end
  end
end
