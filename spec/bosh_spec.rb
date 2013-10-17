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
      /-C [^ ]+ -t http:\/\/example.com -u boshuser -p boshpass#{options[:interactive] ? "" : " -n"}/
    end

    def bosh_command(command)
      [ /bundle exec bosh #{bosh_flags} #{command}/,
        command_options_with_transient_bosh_config
      ]
    end

    describe "creating and uploading releases" do
      around do |example|
        Dir.mktmpdir("release_repo") do |release_repo|
          @release_repo = release_repo
          example.call
        end
      end

      let(:dev_yml) { File.join(@release_repo, "config", "dev.yml") }

      def bosh_command_in_release(command)
        [ /cd #{@release_repo} && bundle exec bosh #{bosh_flags} #{command}/,
          command_options_with_transient_bosh_config
        ]
      end

      def self.it_sets_up_the_release_name
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
                "dev_name" => release_name, "foo" => "bar"
              )
            end
          end

          context "when config/dev.yml does NOT exist" do
            it "writes it with the release name 'cf'" do
              expect {
                create_and_upload_release
              }.to change {
                YAML.load_file(dev_yml) if File.exists?(dev_yml)
              }.from(nil).to("dev_name" => release_name)
            end
          end
        end
      end

      def self.it_resets_config_final
        it "resets config/final.yml before creating the release" do
          create_and_upload_release

          expect(runner).to have_executed_serially(
             "cd #{@release_repo} && git checkout -- config/final.yml",
             /create release/
          )
        end
      end

      describe "#create_and_upload_dev_release" do
        let(:release_name) { "some-release-name" }

        def create_and_upload_release
          subject.create_and_upload_dev_release(@release_repo, release_name)
        end

        it_sets_up_the_release_name
        it_resets_config_final

        it "logs the important bits" do
          create_and_upload_release

          expect(logger).to have_logged("setting release name to 'some-release-name'")
          expect(logger).to have_logged("creating dev release")
          expect(logger).to have_logged("uploading release")
        end

        it "creates a dev release via bosh create release" do
          create_and_upload_release

          expect(runner).to have_executed_serially(
            bosh_command_in_release("create release"),
            bosh_command_in_release("upload release --skip-if-exists"),
          )
        end
      end

      describe "#create_and_upload_final_release" do
        let(:release_name) { "some-release-name" }
        let(:private_yml) { File.join(@release_repo, "config", "private.yml") }

        def create_and_upload_release
          subject.create_and_upload_final_release(@release_repo, release_name, "/some/config/private.yml")
        end

        it_sets_up_the_release_name
        it_resets_config_final

        it "logs the important bits" do
          create_and_upload_release

          expect(logger).to have_logged("setting release name to 'some-release-name'")
          expect(logger).to have_logged("creating final release")
          expect(logger).to have_logged("uploading release")
        end

        it "executes bosh create release --final, resetting bosh crap" do
          create_and_upload_release

          expect(runner).to have_executed_serially(
            bosh_command_in_release("create release"),
            "cd #@release_repo && git checkout -- config/final.yml .final_builds/",
            "cp /some/config/private.yml #{private_yml}",
            bosh_command_in_release("create release --final"),
            bosh_command_in_release("upload release --skip-if-exists"),
          )
        end

        it "logs that it's creating a final release" do
          create_and_upload_release
          expect(logger).to have_logged("creating final release")
        end

        context "when the Bosh was created with the :rebase option" do
          let(:options) { { interactive: false, rebase: true } }

          it "uploads the release to the Bosh director using --rebase" do
            create_and_upload_release

            expect(runner).to have_executed_serially(
              bosh_command_in_release("upload release --skip-if-exists --rebase")
            )
          end
        end
      end
    end

    describe "#set_deployment" do
      it "sets the deployment" do
        subject.set_deployment("my-manifest.yml")

        expect(runner).to have_executed_serially(
          [ "bundle exec bosh -n target http://example.com",
            command_options_with_transient_bosh_config
          ],
          bosh_command("deployment my-manifest.yml"),
        )
      end

      it "logs what it's setting the deployment to" do
        subject.set_deployment("my-manifest.yml")

        expect(logger).to have_logged("setting deployment to my-manifest.yml")
      end
    end

    describe "#deploy" do
      it "sets the deployment and deploys" do
        subject.deploy

        expect(runner).to have_executed_serially(
          [ /yes yes | bundle exec bosh -C [^ ]+ -t http:\/\/example.com -u boshuser -p boshpass deploy/,
            command_options_with_transient_bosh_config
          ]
        )
      end

      it "logs that it's deploying" do
        subject.deploy

        expect(logger).to have_logged("DEPLOYING!")
      end

      context "when interactive" do
        before { options[:interactive] = true }

        it "does not pipe yes yes" do
          subject.deploy

          expect(runner).to have_executed_serially(
            [ /bundle exec bosh -C [^ ]+ -t http:\/\/example.com -u boshuser -p boshpass deploy/,
              command_options_with_transient_bosh_config
            ]
          )
        end
      end
    end
  end
end
