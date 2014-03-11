require 'spec_helper'
require 'cf_deployer/cf_deploy'
require 'cf_deployer/command_runner'
require 'cf_deployer/deploy_environment'
require 'cf_deployer/deployment'
require 'cf_deployer/deployment_strategy'
require 'cf_deployer/release_manifest_generator'
require 'cf_deployer/options_parser'

module CfDeployer
  describe CfDeploy do
    let(:bosh_environment) { {} }
    let(:promote_branch) { 'cool_branch' }
    let(:logger) { double(Logger).as_null_object }

    let(:deploy_environment) do
      double(DeployEnvironment,
             strategy: double(DeploymentStrategy).as_null_object,
             deployment: double(Deployment, bosh_environment: bosh_environment),
             manifest_generator: double(ReleaseManifestGenerator),
             runner: double(CommandRunner),
             options: double(:options,
                             deployment_name: 'anchors aweigh',
                             install_tokens: true,
                             push_branch: 'an_awesome_branch',
                             promote_branch: promote_branch
             )
      )
    end

    subject(:cf_deploy) { described_class.new(deploy_environment, logger) }

    describe '.build' do
      it 'constructs a DeployEnvironment and passes it to .new' do
        options = double(OptionsParser::Options)
        deploy_environment = double(DeployEnvironment)
        expect(DeployEnvironment).to receive(:new).with(options, logger).and_return(deploy_environment)

        cf_deploy = double(CfDeploy)
        expect(CfDeploy).to receive(:new).with(deploy_environment, logger).and_return(cf_deploy)

        expect(CfDeploy.build(options, logger)).to eq(cf_deploy)
      end
    end

    describe '#initialize' do
      context 'when the bosh environment specifies the datadog environment variables' do
        let(:fake_dogapi) { double(Dogapi::Client) }
        let(:bosh_environment) do
          {'DATADOG_API_KEY' => 'api', 'DATADOG_APPLICATION_KEY' => 'application'}
        end

        it 'installs the datadog hooks' do
          fake_datadog_emitter = double(DatadogEmitter)
          allow(DatadogEmitter).to receive(:new).and_return(fake_datadog_emitter)

          CfDeploy.new(deploy_environment, logger)
          expect(deploy_environment.strategy).to have_received(:install_hook).with(fake_datadog_emitter)
        end

        it 'creates the hooks correctly' do
          expect(Dogapi::Client).to receive(:new).with('api', 'application').and_return(fake_dogapi)
          expect(DatadogEmitter).to receive(:new).with(logger, fake_dogapi, deploy_environment.options.deployment_name)

          CfDeploy.new(deploy_environment, logger)
        end
      end

      describe 'token hooks' do
        it 'installs the token hooks' do
          fake_token_installer = double(TokenInstaller)
          allow(TokenInstaller).to receive(:new).and_return(fake_token_installer)

          CfDeploy.new(deploy_environment, logger)
          expect(deploy_environment.strategy).to have_received(:install_hook).with(fake_token_installer)
        end

        it 'creates the hooks correctly' do
          expect(TokenInstaller).to receive(:new).with(deploy_environment.manifest_generator, deploy_environment.runner)

          CfDeploy.new(deploy_environment, logger)
        end
      end
    end

    describe '#create_release' do
      it 'delegates to the DeployEnvironment#strategy' do
        cf_deploy.create_release
        expect(deploy_environment.strategy).to have_received(:create_release)
      end
    end

    describe '#upload_release' do
      it 'delegates to the DeployEnvironment#strategy' do
        cf_deploy.upload_release
        expect(deploy_environment.strategy).to have_received(:upload_release)
      end
    end

    describe '#deploy_release' do
      it 'delegates to the DeployEnvironment#strategy' do
        cf_deploy.deploy_release
        expect(deploy_environment.strategy).to have_received(:deploy_release)
      end
    end

    describe '#tag_and_push_final_release' do
      it 'delegates to the DeployEnvironment#strategy' do
        cf_deploy.tag_and_push_final_release
        expect(deploy_environment.strategy).to have_received(:tag_and_push_final_release).with('an_awesome_branch')
      end
    end

    describe '#promote_release' do
      it 'delegates to the DeployEnvironment#strategy' do
        cf_deploy.promote_release
        expect(deploy_environment.strategy).to have_received(:promote_release).with(deploy_environment.options.promote_branch)
      end

      context 'when the promote_branch is not set' do
        let(:promote_branch) { nil }

        it 'does not do any branch promotion' do
          cf_deploy.promote_release
          expect(deploy_environment.strategy).not_to have_received(:promote_release)
        end
      end
    end
  end
end
