require "spec_helper"
require "cf_deployer/release_manifest_generator"
require "cf_deployer/hooks/token_installer"

module CfDeployer
  describe TokenInstaller do
    let(:generated_manifest) { File.open(File.expand_path('../../fixtures/appdirect-manifest.yml', __FILE__)) }

    let(:runner) { FakeCommandRunner.new }

    let(:release) { FakeReleaseRepo.new './repos/appdirect-gateway' }
    let(:manifest_generator) { ReleaseManifestGenerator.new runner, release, 'doesnt-matter', generated_manifest.path }

    subject { described_class.new(manifest_generator, runner) }

    describe '#post_deploy' do
      it 'registers tokens with the cloud controller' do
        manifest = manifest_generator.get_manifest

        username, password = manifest.services_credentials

        subject.post_deploy

        # should be two tokens from fixture, one AD and one mysql
        tokens = manifest.service_tokens

        expect(runner).to have_executed_serially(
          "cf target #{manifest.api_endpoint}",
          "cf login --username '#{username}' --password '#{password}' --organization pivotal",
          "cf create-service-auth-token '#{tokens[0]['name']}' '#{tokens[0]['provider']}' --token '#{tokens[0]['auth_token']}' 2>/dev/null || true",
          "cf create-service-auth-token '#{tokens[1]['name']}' '#{tokens[1]['provider']}' --token '#{tokens[1]['auth_token']}' 2>/dev/null || true"
        )
      end
    end
  end
end
