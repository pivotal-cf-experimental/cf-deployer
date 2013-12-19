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

    subject(:bosh) { described_class.new(logger, runner, bosh_environment, options) }

    def command_options_with_transient_bosh_config
      proc do |options|
        next unless options[:environment]

        config = options[:environment]["BOSH_CONFIG"]
        next unless config

        File.exists?(config)
      end
    end

    def bosh_flags
      /-t http:\/\/example.com -u boshuser -p boshpass#{options[:interactive] ? "" : " -n"}/
    end

    def bosh_command(command)
      [ /set -o pipefail && bosh #{bosh_flags} #{command}/,
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
        [ /set -o pipefail && cd #{@release_repo} && bosh #{bosh_flags} #{command}/,
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
          bosh.create_and_upload_dev_release(@release_repo, release_name)
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

        context "when the Bosh was created with the :rebase option" do
          let(:options) { { interactive: false, rebase: true } }

          it "uploads the release to the Bosh director using --rebase" do
            create_and_upload_release

            expect(runner).to have_executed_serially(
              bosh_command_in_release("upload release --skip-if-exists --rebase")
            )
          end

          it "logs the bosh output to a temporary bosh_output location" do
            create_and_upload_release

            expect(runner).to have_executed_serially(
              bosh_command_in_release(
                "upload release --skip-if-exists --rebase \\| tee #{bosh.bosh_output_file.path}"
              )
            )
          end

          context "when the rebase has no job or package changes" do
            it "continues without throwing error, despite bosh's unsucessful return code" do
              runner.when_running(/upload release .* --rebase/) do
                File.open(bosh.bosh_output_file.path, "w") do |file|
                  file.write("Rebase is attempted without any job or package changes")
                end

                raise CommandRunner::CommandFailed
              end

              expect { create_and_upload_release }.to_not raise_error
            end
          end

          context "when the bosh upload fails, without the error 'the rebase has no job or package changes'" do
            it "continues without throwing error, despite bosh's unsucessful return code" do
              runner.when_running(/upload release .* --rebase/) do
                raise CommandRunner::CommandFailed
              end

              expect{ create_and_upload_release }.to raise_error CommandRunner::CommandFailed
            end
          end
        end

        context "when the Bosh was created with the :dirty option" do
          let(:options) { { interactive: false, dirty: true } }

          it "creates the release with --force" do
            create_and_upload_release

            expect(runner).to have_executed_serially(
              bosh_command_in_release("create release --force")
            )
          end
        end
      end

      describe "#create_and_upload_final_release" do
        let(:release_name) { "some-release-name" }
        let(:private_yml) { File.join(@release_repo, "config", "private.yml") }

        def create_and_upload_release
          bosh.create_and_upload_final_release(@release_repo, release_name, "/some/config/private.yml")
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
        bosh.set_deployment("my-manifest.yml")

        expect(runner).to have_executed_serially(
          [ "set -o pipefail &&  bosh -n target http://example.com",
            command_options_with_transient_bosh_config
          ],
          bosh_command("deployment my-manifest.yml"),
        )
      end

      it "logs what it's setting the deployment to" do
        bosh.set_deployment("my-manifest.yml")

        expect(logger).to have_logged("setting deployment to my-manifest.yml")
      end
    end

    describe "#deploy" do
      it "shows the deployment diff and then deploys" do
        bosh.deploy

        expect(runner).to have_executed_serially(
          [ "set -o pipefail && echo no | bosh -t http://example.com -u boshuser -p boshpass deploy || true",
            command_options_with_transient_bosh_config
          ],
          [ "set -o pipefail &&  bosh -t http://example.com -u boshuser -p boshpass -n deploy",
            command_options_with_transient_bosh_config
          ],
        )
      end

      it "logs that it's deploying" do
        bosh.deploy

        expect(logger).to have_logged("DEPLOYING!")
      end

      context "when interactive" do
        before { options[:interactive] = true }

        it "does not pipe yes yes" do
          bosh.deploy

          expect(runner).to have_executed_serially(
            [ /bosh -t http:\/\/example.com -u boshuser -p boshpass deploy/,
              command_options_with_transient_bosh_config
            ]
          )
        end
      end
    end

    describe "#director_uuid" do
      context "when dry-run option is passed in" do
        before do
          options[:dry_run] = true
        end

        it "does not load bosh config because bosh target has not actually run" do
          expect {
            bosh.director_uuid
          }.not_to raise_error
        end
      end
    end
  end
end
