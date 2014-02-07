require "fileutils"

require "spec_helper"
require "cf_deployer/deployment"

module CfDeployer
  describe Deployment do
    before do
      @deployment_path = Dir.mktmpdir("deployment")
    end

    after { FileUtils.rm_rf(@deployment_path) }

    subject { described_class.new(@deployment_path) }

    describe "#bosh_environment" do
      before do
        IO.unstub(:popen)
        File.open(File.join(@deployment_path, "bosh_environment"), "w") do |io|
          io.write <<EOF
export FOO=1
export BAR=2
EOF
        end
      end

      it "returns a hash of the environment variables" do
        expect(subject.bosh_environment).to eq("FOO" => "1", "BAR" => "2")
      end
    end

    describe "#stub_files" do
      let(:generic)  { File.join(@deployment_path, "cf-stub.yml") }
      let(:aws)      { File.join(@deployment_path, "cf-aws-stub.yml") }
      let(:secrets)  { File.join(@deployment_path, "cf-shared-secrets.yml") }
      let(:non_stub) { File.join(@deployment_path, "cf-non-stub.yml") }

      before do
        [generic, aws, secrets, non_stub].each do |file|
          File.open(file, "w") do |io|
            io.write("--- {}")
          end
        end
      end

      it "returns the detected stub files" do
        expect(subject.stub_files).to include(generic)
        expect(subject.stub_files).to include(aws)
        expect(subject.stub_files).to include(secrets)
        expect(subject.stub_files).to_not include(non_stub)
      end
    end

    describe "#private_config" do
      let(:private_yml) { File.join(@deployment_path, "config", "private.yml") }

      context "when config/private.yml exists" do
        before do
          FileUtils.mkdir_p(File.dirname(private_yml))
          File.open(private_yml, "w") do |io|
            io.write("--- {}")
          end
        end

        it "returns the path to it" do
          expect(subject.private_config).to eq(private_yml)
        end
      end

      context "when config/private.yml does NOT exist" do
        it "returns nil" do
          expect(subject.private_config).to be_nil
        end
      end
    end
  end
end
