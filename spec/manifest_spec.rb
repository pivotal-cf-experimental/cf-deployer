require "spec_helper"
require "cf_deployer/manifest"

module CfDeployer
  describe Manifest do
    let(:runner) { FakeCommandRunner.new }

    subject { described_class.new(runner) }

    around do |example|
      Dir.mktmpdir("working_dir") do |working_dir|
        Dir.chdir(working_dir, &example)
      end
    end

    describe "#generate" do
      it "installs and updates spiff" do
        subject.generate("./repos/cf-release", "aws", ["/woah", "/stub/files"])

        gospace = File.join(Dir.pwd, "gospace")

        expect(runner).to have_executed_serially(
          ["go get -u -v github.com/vito/spiff", environment: { "GOPATH" => gospace }],
          [ "./repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml",
            environment: { "PATH" => "#{gospace}/bin:/usr/bin:/bin" }
          ]
        )
      end

      it "generates the deployment manifest" do
        subject.generate("./repos/cf-release", "aws", ["/woah", "/stub/files"])

        expect(runner).to have_executed_serially(
          "./repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml",
        )
      end

      it "returns the path to the generated manifest" do
        result = subject.generate("./repos/cf-release", "aws", ["/woah", "/stub/files"])

        expect(result).to eq("#{Dir.pwd}/new_deployment.yml")
      end
    end
  end
end