require "spec_helper"
require "cf_deployer/manifest"

module CfDeployer
  describe ReleaseManifest do
    let(:runner) { FakeCommandRunner.new }
    let(:release) { FakeReleaseRepo.new "./repos/cf-release" }

    subject { described_class.new(runner, release, "aws", "new_deployment.yml") }

    around do |example|
      Dir.mktmpdir("working_dir") do |working_dir|
        Dir.chdir(working_dir, &example)
      end
    end

    describe "#generate!" do
      it "installs and updates spiff" do
        subject.generate!(["/woah", "/stub/files"])

        gospace = File.join(Dir.pwd, "gospace")

        expect(runner).to have_executed_serially(
          ["go get -u -v github.com/vito/spiff", environment: { "GOPATH" => gospace }],
          [ "./repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml",
            environment: { "PATH" => "#{gospace}/bin:/usr/bin:/bin" }
          ]
        )
      end

      it "generates the deployment manifest" do
        subject.generate!(["/woah", "/stub/files"])

        expect(runner).to have_executed_serially(
          "./repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml",
        )
      end

      it "returns the full path to the generated manifest" do
        result = subject.generate!(["/woah", "/stub/files"])

        expect(result).to eq("#{Dir.pwd}/new_deployment.yml")
      end
    end

    describe "#appdirect_services" do
      context "when the manifest has not been generated" do
        it "raises a ManifestNotGenerated" do
          expect {
            subject.appdirect_services
          }.to raise_error(ReleaseManifest::ManifestNotGenerated)
        end
      end

      context "when the manifest has been generated" do
        context "and the manifest does not contain the services" do
          before do
            runner.when_running(/generate_deployment_manifest/) do
              File.open("new_deployment.yml", "w") do |io|
                io.write <<EOF
---
properties:
EOF
              end
            end

            subject.generate!([])
          end

          it "returns nil" do
            expect(subject.appdirect_services).to be_nil
          end
        end

        context "and the manifest contains properties.appdirect_gateway.services" do
          before do
            runner.when_running(/generate_deployment_manifest/) do
              File.open("new_deployment.yml", "w") do |io|
                io.write <<EOF
---
properties:
  appdirect_gateway:
    services:
    - name: service-name
      provider: service-provider
      auth_token: service-auth-token
    - name: another-service-name
      provider: another-service-provider
      auth_token: another-service-auth-token
EOF
              end
            end

            subject.generate!([])
          end

          it "returns the tokens as an array of hashes" do
            expect(subject.appdirect_services).to eq([
              { label: "service-name",
                provider: "service-provider",
                token: "service-auth-token"
              },
              { label: "another-service-name",
                provider: "another-service-provider",
                token: "another-service-auth-token"
              },
            ])
          end
        end
      end
    end

    describe "#admin_credentials" do
      context "when the manifest has not been generated" do
        it "raises a ManifestNotGenerated" do
          expect {
            subject.admin_credentials
          }.to raise_error(ReleaseManifest::ManifestNotGenerated)
        end
      end

      context "when the manifest has been generated" do
        context "and the manifest does not contain scim information" do
          before do
            runner.when_running(/generate_deployment_manifest/) do
              File.open("new_deployment.yml", "w") do |io|
                io.write <<EOF
---
properties:
EOF
              end
            end

            subject.generate!([])
          end

          it "returns nil" do
            expect(subject.admin_credentials).to be_nil
          end
        end

        context "and the manifest contains properties.uaa.scim.users" do
          context "and there is an admin user" do
            before do
              runner.when_running(/generate_deployment_manifest/) do
                File.open("new_deployment.yml", "w") do |io|
                  io.write <<EOF
---
properties:
  uaa:
    scim:
      users:
      - admin|secret|...
EOF
                end
              end

              subject.generate!([])
            end

            it "returns their username and password" do
              expect(subject.admin_credentials).to eq(["admin", "secret"])
            end
          end

          context "and there is no admin user" do
            before do
              runner.when_running(/generate_deployment_manifest/) do
                File.open("new_deployment.yml", "w") do |io|
                  io.write <<EOF
---
properties:
  uaa:
    scim:
      users:
      - non-admin|secret|...
EOF
                end
              end

              subject.generate!([])
            end

            it "returns nil" do
              expect(subject.admin_credentials).to be_nil
            end
          end
        end
      end
    end

    describe "#api_endpoint" do
      context "when the manifest has not been generated" do
        it "raises a ManifestNotGenerated" do
          expect {
            subject.admin_credentials
          }.to raise_error(ReleaseManifest::ManifestNotGenerated)
        end
      end

      context "when the manifest has been generated" do
        context "and it does not contain the api endpoint" do
          before do
            runner.when_running(/generate_deployment_manifest/) do
              File.open("new_deployment.yml", "w") do |io|
                io.write <<EOF
---
properties:
EOF
              end
            end

            subject.generate!([])
          end

          it "returns nil" do
            expect(subject.api_endpoint).to be_nil
          end
        end

        context "and the manifest contains properties.uaa.scim.users" do
          before do
            runner.when_running(/generate_deployment_manifest/) do
              File.open("new_deployment.yml", "w") do |io|
                io.write <<EOF
---
properties:
  cc:
    srv_api_uri: http://api.example.com
EOF
              end
            end

            subject.generate!([])
          end

          it "returns their username and password" do
            expect(subject.api_endpoint).to eq("http://api.example.com")
          end
        end
      end
    end
  end
end
