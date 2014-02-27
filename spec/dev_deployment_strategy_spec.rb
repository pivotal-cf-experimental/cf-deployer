require 'spec_helper'
require 'cf_deployer/deployment'
require 'cf_deployer/dev_deployment_strategy'

module CfDeployer
  describe DevDeploymentStrategy do
    let(:deployment_path) { Dir.mktmpdir('deployment_path') }

    let(:bosh) { FakeBosh.new }
    let(:deployment) { Deployment.new(deployment_path) }
    let(:release_repo) { FakeReleaseRepo.new './repos/cf-release' }
    let(:manifest) { FakeReleaseManifestGenerator.new 'some-manifest.yml' }
    let(:release_name) { 'some-release-name' }

    subject { described_class.new(bosh, deployment, manifest, release_name, release_repo) }

    after { FileUtils.rm_rf(deployment_path) }

    describe '#create_release' do
      it 'creates dev release with the right name' do
        expect {
          subject.create_release
        }.to change {
          [bosh.dev_release, bosh.dev_release_name]
        }.to([release_repo.path, 'some-release-name'])
      end
    end

    describe '#upload_release' do
      it 'uploads the created release' do
        expect {
          subject.upload_release
        }.to change {
          bosh.uploaded_release
        }.to(release_repo.path)
      end
    end

    describe '#promote_release' do
      it 'promotes the dev release' do
        expect {
          subject.promote_release 'some-branch'
        }.to change {
          release_repo.promoted_dev_release
        }.to('some-branch')
      end
    end
  end
end
