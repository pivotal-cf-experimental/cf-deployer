require "base64"
require "json"

require "spec_helper"
require "cf_deployer/deployment"
require "cf_deployer/release_manifest_generator"
require "cf_deployer/deployment_strategy"

module CfDeployer
  describe DeploymentStrategy do
    let(:deployment_path) { Dir.mktmpdir("deployment_path") }
    let(:generated_manifest) { Tempfile.new("generated-manifest.yml") }

    let(:runner) { FakeCommandRunner.new }

    let(:bosh) { FakeBosh.new }
    let(:deployment) { Deployment.new(deployment_path) }
    let(:release_repo) { FakeReleaseRepo.new "./repos/cf-release" }
    let(:manifest) { FakeReleaseManifestGenerator.new "some-manifest.yml" }
    let(:release_name) { "some-release-name" }

    subject { described_class.new(bosh, deployment, manifest, release_name, release_repo) }

    it "does not implement #create_release" do
      expect { subject.create_release }.to raise_error(NotImplementedError)
    end

    it "does not implement #upload_release" do
      expect { subject.upload_release }.to raise_error(NotImplementedError)
    end

    describe "#deploy_release" do
      let(:generic_stub) { File.join(deployment_path, "cf-stub.yml") }
      let(:shared_secrets) { File.join(deployment_path, "cf-shared-secrets.yml") }

      before do
        bosh.create_dev_release(release_repo.path, release_name)
        bosh.upload_release(release_repo.path)

        File.open(generic_stub, "w") do |io|
          io.write("--- {}")
        end

        File.open(shared_secrets, "w") do |io|
          io.write("--- {}")
        end
      end

      it "generates the manifest using the stubs" do
        expect {
          subject.deploy_release
        }.to change {
          manifest.stubs
        }.to([generic_stub, shared_secrets])
      end

      it "sets the deployment" do
        expect {
          subject.deploy_release
        }.to change {
          bosh.deployment
        }.to("some-manifest.yml")
      end

      it "deploys" do
        expect {
          subject.deploy_release
        }.to change {
          bosh.deployed
        }.to(true)
      end
    end

    describe "#install_hook" do
      let(:some_hook) do
        Class.new do
          attr_reader :triggered_pre_deploy, :triggered_post_deploy

          def pre_deploy
            @triggered_pre_deploy = true
          end

          def post_deploy
            @triggered_post_deploy = true
          end
        end.new
      end

      it "sets up a hook for deploying" do
        bosh.create_dev_release(release_repo.path, release_name)
        bosh.upload_release(release_repo.path)

        subject.install_hook(some_hook)

        expect {
          subject.deploy_release
        }.to change {
          [some_hook.triggered_pre_deploy, some_hook.triggered_post_deploy]
        }.to([true, true])
      end
    end
  end
end
