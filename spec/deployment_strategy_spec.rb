require "base64"
require "json"
require "webmock/rspec"

require "spec_helper"
require "cf_deployer/deployment"
require "cf_deployer/manifest_generator"
require "cf_deployer/deployment_strategy"

module CfDeployer
  describe DeploymentStrategy do
    let(:deployment_path) { Dir.mktmpdir("deployment_path") }
    let(:generated_manifest) { Tempfile.new("generated-manifest.yml") }

    let(:runner) { FakeCommandRunner.new }

    let(:bosh) { FakeBosh.new }
    let(:deployment) { Deployment.new(deployment_path) }
    let(:release) { FakeReleaseRepo.new "./repos/cf-release" }
    let(:manifest_generator) { ReleaseManifestGenerator.new runner, release, "doesnt-matter", generated_manifest.path }
    let(:release_name) { "some-release-name" }

    subject { described_class.new(bosh, deployment, manifest_generator, release_name => release) }

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
        subject.stub(:do_deploy)

        subject.install_hook(some_hook)

        expect {
          subject.deploy!
        }.to change {
          [ some_hook.triggered_pre_deploy,
            some_hook.triggered_post_deploy,
          ]
        }.to([true, true])
      end
    end

    describe "#deploy!" do
      it "calls pre_deploy and post_deploy hooks before and after deploying" do
        sequence = []

        some_hook =
          Class.new do
            define_method(:pre_deploy) do
              sequence << :pre_deploy
            end

            define_method(:post_deploy) do
              sequence << :post_deploy
            end
          end

        subject.install_hook(some_hook.new)

        subject.stub(:do_deploy) { sequence << :deploying }

        expect {
          subject.deploy!
        }.to change {
          sequence
        }.from([]).to([:pre_deploy, :deploying, :post_deploy])
      end
    end

    describe "#promote!" do
      it "calls pre_promote and post_promote hooks before and after promoteing" do
        sequence = []

        some_hook =
          Class.new do
            define_method(:pre_promote) do |x|
              sequence << [:pre_promote, x]
            end

            define_method(:post_promote) do |x|
              sequence << [:post_promote, x]
            end
          end

        subject.install_hook(some_hook.new)

        subject.stub(:do_promote_to) { |x| sequence << [:promoting_to, x] }

        expect {
          subject.promote_to!("release-candidate")
        }.to change {
          sequence
        }.from([]).to([
          [:pre_promote, "release-candidate"],
          [:promoting_to, "release-candidate"],
          [:post_promote, "release-candidate"],
        ])
      end
    end
  end
end
