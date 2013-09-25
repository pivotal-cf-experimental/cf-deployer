require "spec_helper"
require "cf_deployer/manifest"

describe Manifest do
  let(:runner) { FakeCommandRunner.new }

  subject { described_class.new(runner) }

  around do |example|
    Dir.mktmpdir("working_dir") do |working_dir|
      Dir.chdir(working_dir, &example)
    end
  end

  describe "#generate" do
    it "generates the deployment manifest" do
      subject.generate("./repos/cf-release", "aws", ["/woah", "/stub/files"])

      expect(runner).to have_executed_serially(
        [ "./repos/cf-release/generate_deployment_manifest aws /woah /stub/files",

          # buckle up
          proc do |options|
            options[:out].is_a?(File) && \
              options[:out].path =~ /\.yml$/
          end
        ]
      )
    end

    it "returns the path to the generated manifest" do
      result = subject.generate("./repos/cf-release", "aws", ["/woah", "/stub/files"])

      expect(result).to eq("#{Dir.pwd}/new_deployment.yml")
    end
  end
end