require "spec_helper"
require "cf_deployer/deployment"
require "cf_deployer/dev_deployment_strategy"

module CfDeployer
  describe DevDeploymentStrategy do
    let(:deployment_path) { Dir.mktmpdir("deployment_path") }

    let(:bosh) { FakeBosh.new }
    let(:deployment) { Deployment.new(deployment_path) }
    let(:release_repo) { FakeReleaseRepo.new "./repos/cf-release" }
    let(:manifest) { FakeManifest.new "some-manifest.yml" }
    let(:release_name) { "some-release-name" }

    subject { described_class.new(bosh, deployment, manifest, release_name, release_repo) }

    after { FileUtils.rm_rf(deployment_path) }

    describe "#create_release" do
      it "creates dev release with the right name" do
        expect {
          subject.create_release
        }.to change {
          bosh.dev_release
        }.to([release_repo.path, "some-release-name"])
      end
    end

    describe "#upload_release" do
      it "uploads the created release" do
        expect {
          subject.upload_release
        }.to change {
          bosh.release_path
        }.to(release_repo.path)
      end
    end

    describe "#deploy!" do
      let(:generic_stub) { File.join(deployment_path, "cf-stub.yml") }
      let(:shared_secrets) { File.join(deployment_path, "cf-shared-secrets.yml") }

      before do
        File.open(generic_stub, "w") do |io|
          io.write("--- {}")
        end

        File.open(shared_secrets, "w") do |io|
          io.write("--- {}")
        end
      end

      it "creates and uploads a dev release with the right name" do
        expect {
          subject.deploy!
        }.to change {
          bosh.dev_release
        }.to([release_repo.path, "some-release-name"])
      end

      it "generates the manifest using the stubs" do
        expect {
          subject.deploy!
        }.to change {
          manifest.stubs
        }.to([generic_stub, shared_secrets])
      end

      it "sets the deployment" do
        expect {
          subject.deploy!
        }.to change {
          bosh.deployment
        }.to("some-manifest.yml")
      end

      it "deploys" do
        expect {
          subject.deploy!
        }.to change {
          bosh.deployed
        }.to(true)
      end
    end

    describe "#promote!" do
      it "promotes the dev release" do
        expect {
          subject.promote_to! "some-branch"
        }.to change {
          release_repo.promoted_dev_release
        }.to("some-branch")
      end
    end
  end
end
