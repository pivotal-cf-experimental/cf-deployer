require "fileutils"
require "yaml"

require "spec_helper"
require "cf_deployer/bosh"

module CfDeployer
  describe Bosh do
    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }

    let(:bosh_environment) do
      { "BOSH_DIRECTOR" => "http://example.com",
        "BOSH_USER" => "boshuser",
        "BOSH_PASSWORD" => "boshpass",
      }
    end

    let(:options) { { interactive: false } }

    subject { described_class.new(logger, runner, bosh_environment, options) }

    def command_options_with_transient_bosh_config
      proc do |options|
        next unless options[:environment]

        config = options[:environment]["BOSH_CONFIG"]
        next unless config

        File.exists?(config)
      end
    end

    def bosh_flags
      "-t http://example.com -u boshuser -p boshpass#{options[:interactive] ? "" : " -n"}"
    end

    def bosh_command(command)
      [ "bundle exec bosh #{bosh_flags} #{command}",
        command_options_with_transient_bosh_config
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

      def bosh_command_in_release(command)
        [ "cd #{@release_repo} && bundle exec bosh #{bosh_flags} #{command}",
          command_options_with_transient_bosh_config
        ]
      end

      it "logs the important bits" do
        create_and_upload_release

        expect(logger).to have_logged("setting release name to 'cf'")
        expect(logger).to have_logged("creating release")
        expect(logger).to have_logged("uploading release")
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
             "cd #{@release_repo} && git checkout -- config/final.yml",
             /create release/
          )
        end

        context "when creating a final release" do
          it "executes bosh create release --final" do
            create_and_upload_release(final: true)

            expect(runner).to have_executed_serially(
              bosh_command_in_release("create release --final"),
              bosh_command_in_release("upload release --skip-if-exists"),
            )
          end

          it "logs that it's creating a final release" do
            create_and_upload_release(final: true)
            expect(logger).to have_logged("creating final release")
          end
        end

        context "when NOT creating a final release" do
          it "creates a dev release via bosh create release" do
            create_and_upload_release

            expect(runner).to have_executed_serially(
              bosh_command_in_release("create release"),
              bosh_command_in_release("upload release --skip-if-exists"),
            )
          end
        end
      end
    end

    describe "#set_deployment" do
      it "sets the deployment" do
        subject.deployment("my-manifest.yml")

        expect(runner).to have_executed_serially(
          [ "bundle exec bosh -n target http://example.com",
            command_options_with_transient_bosh_config
          ],
          bosh_command("deployment my-manifest.yml"),
        )
      end

      it "logs what it's setting the deployment to" do
        subject.deployment("my-manifest.yml")

        expect(logger).to have_logged("setting deployment to my-manifest.yml")
      end
    end

    describe "#deploy" do
      it "sets the deployment and deploys" do
        subject.deploy

        expect(runner).to have_executed_serially(
          [ "yes yes | bundle exec bosh -t http://example.com -u boshuser -p boshpass deploy",
            command_options_with_transient_bosh_config
          ]
        )
      end

      it "logs that it's deploying" do
        subject.deploy

        expect(logger).to have_logged("DEPLOYING!")
      end
    end
  end
end