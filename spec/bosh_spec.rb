require "fileutils"
require "yaml"

require "spec_helper"
require "cf_deployer/bosh"

describe Bosh do
  let(:runner) { FakeCommandRunner.new }

  let(:bosh_environment) do
    { "BOSH_DIRECTOR" => "http://example.com",
      "BOSH_USER" => "boshuser",
      "BOSH_PASSWORD" => "boshpass",
    }
  end

  let(:options) { {} }

  subject { described_class.new(runner, bosh_environment, options) }

  def bosh_command(command)
    [ "bundle exec bosh -t http://example.com -u boshuser -p boshpass #{command}",
      environment: { "BOSH_CONFIG" => "" }
    ]
  end

  describe "#create_and_upload_release" do
    around do |example|
      Dir.mktmpdir("release_repo") do |release_repo|
        @release_repo = release_repo
        example.call
      end
    end

    let(:dev_yml) { File.join(@release_repo, "config", "dev.yml") }

    def create_and_upload_release(options = {})
      subject.create_and_upload_release(@release_repo, options)
    end

    describe "setting the release name" do
      context "when config/dev.yml exists" do
        before do
          FileUtils.mkdir_p(File.join(@release_repo, "config"))

          File.open(dev_yml, "w") do |io|
            YAML.dump({ "dev_name" => "bosh-release", "foo" => "bar" }, io)
          end
        end

        it "updates the release name to 'cf'" do
          expect {
            create_and_upload_release
          }.to change {
            YAML.load_file(dev_yml)
          }.from(
            "dev_name" => "bosh-release", "foo" => "bar"
          ).to(
            "dev_name" => "cf", "foo" => "bar"
          )
        end
      end

      context "when config/dev.yml does NOT exist" do
        it "writes it with the release name 'cf'" do
          expect {
            create_and_upload_release
          }.to change {
            YAML.load_file(dev_yml) if File.exists?(dev_yml)
          }.from(nil).to("dev_name" => "cf")
        end
      end
    end

    describe "creating and uploading the release" do
      it "resets config/final.yml before creating the release" do
        create_and_upload_release

        expect(runner).to have_executed_serially(
           "git checkout -- config/final.yml",
           /create release/
        )
      end

      context "when creating a final release" do
        it "executes bosh create release --final" do
          create_and_upload_release(final: true)

          expect(runner).to have_executed_serially(
            bosh_command("create release --final"),
            bosh_command("upload release --skip-if-exists"),
          )
        end
      end

      context "when NOT creating a final release" do
        it "creates a dev release via bosh create release" do
          create_and_upload_release

          expect(runner).to have_executed_serially(
            bosh_command("create release"),
            bosh_command("upload release --skip-if-exists"),
          )
        end
      end
    end
  end

  describe "#deploy" do
    it "sets the deployment and deploys" do
      subject.deploy("my-manifest.yml")

      expect(runner).to have_executed_serially(
        bosh_command("deployment my-manifest.yml"),
        [ "yes yes | bundle exec bosh -t http://example.com -u boshuser -p boshpass deploy",
          environment: { "BOSH_CONFIG" => "" }
        ]
      )
    end
  end
end