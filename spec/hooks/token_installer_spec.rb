require "spec_helper"
require "cf_deployer/manifest"
require "cf_deployer/hooks/token_installer"

module CfDeployer
  describe TokenInstaller do
    let(:generated_manifest) { File.open(File.expand_path('../../fixtures/appdirect-manifest.yml', __FILE__)) }

    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }

    let(:release) { FakeReleaseRepo.new './repos/appdirect-gateway' }
    let(:manifest) { ReleaseManifest.new runner, release, 'doesnt-matter', generated_manifest.path }

    subject { described_class.new(logger, manifest, runner) }

    describe '#post_deploy' do
      it 'registers tokens with the cloud controller' do
        username, password = manifest.admin_credentials

        subject.post_deploy

        clear_db_service = manifest.appdirect_tokens.first

        expect(runner).to have_executed_serially(
          "cf target #{manifest.api_endpoint}",
          "cf login --username #{username} --password #{password} --organization pivotal",
          "cf create-service-auth-token #{clear_db_service['name']} #{clear_db_service['provider']} --token #{clear_db_service['auth_token']} 2>/dev/null || true"
        )
      end
    end
  end
end
