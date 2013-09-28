require "base64"
require "json"
require "webmock/rspec"

require "spec_helper"
require "cf_deployer/hooks/service_auth_token_installer"

module CfDeployer
  describe ServiceAuthTokenInstaller do
    let(:generated_manifest) { Tempfile.new("generated-manifest.yml") }

    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }

    let(:release) { FakeReleaseRepo.new "./repos/cf-release" }
    let(:manifest) { ReleaseManifest.new runner, release, "doesnt-matter", generated_manifest.path }

    subject { described_class.new(logger, manifest) }

    describe "#post_deploy" do
      before do
        stub_request(
          :get, "https://example.com/info",
        ).to_return(
          status: 200,
          body: '{"authorization_endpoint": "http://login.example.com"}',
        )

        stub_request(
          :post, "http://cf:@login.example.com/oauth/token",
        ).with(
          body: "grant_type=password&username=admin&password=adminpass",
        ).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            token_type: "bearer",
            access_token: fake_access_token,
          }.to_json
        )
      end

      context "when there are no service tokens" do
        before do
          File.open(generated_manifest.path, "w") do |io|
            io.write <<EOF
---
properties:
  cc:
    srv_api_uri: https://example.com

  uaa:
    scim:
      users:
        - admin|adminpass|x|y|z
EOF
          end
        end

        it "skips installation" do
          subject.post_deploy

          expect(logger).to have_logged(/skipping/)
        end
      end

      context "when there are service tokens" do
        before do
          File.open(generated_manifest.path, "w") do |io|
            io.write <<EOF
---
properties:
  cc:
    srv_api_uri: https://example.com

  uaa:
    scim:
      users:
        - admin|adminpass|x|y|z

  appdirect_gateway:
    services:
      - name: service-name-a
        provider: service-provider-a
        auth_token: service-auth-token-a
      - name: service-name-b
        provider: service-provider-b
        auth_token: service-auth-token-b
      - name: service-name-c
        provider: service-provider-c
        auth_token: service-auth-token-c
EOF
          end
        end

        def stub_creation_for(name)
          stub_request(
            :post, "https://example.com/v2/service_auth_tokens"
          ).with(
            headers: { "Content-Type" => "application/json" },
            body: {
              label: "service-name-#{name}",
              provider: "service-provider-#{name}",
              token: "service-auth-token-#{name}",
            }.to_json
          ).to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: {
              metadata: {
                guid: "some-guid",
              }
            }.to_json,
          )
        end

        def stub_creation_taken_failure_for(name)
          stub_request(
            :post, "https://example.com/v2/service_auth_tokens"
          ).with(
            headers: { "Content-Type" => "application/json" },
            body: {
              label: "service-name-#{name}",
              provider: "service-provider-#{name}",
              token: "service-auth-token-#{name}",
            }.to_json
          ).to_return(
            status: 400,
            headers: { "Content-Type" => "application/json" },
            body: {
              code: 50002,
              description: "already registered!",
            }.to_json,
          )
        end

        def stub_creation_unknown_failure_for(name)
          stub_request(
            :post, "https://example.com/v2/service_auth_tokens"
          ).with(
            headers: { "Content-Type" => "application/json" },
            body: {
              label: "service-name-#{name}",
              provider: "service-provider-#{name}",
              token: "service-auth-token-#{name}",
            }.to_json
          ).to_return(
            status: 400,
            headers: { "Content-Type" => "application/json" },
            body: {
              code: 1,
              description: "lol",
            }.to_json,
          )
        end

        it "installs the service auth tokens" do
          create_a = stub_creation_for("a")
          create_b = stub_creation_for("b")
          create_c = stub_creation_for("c")

          subject.post_deploy

          expect(create_a).to have_been_requested
          expect(create_b).to have_been_requested
          expect(create_c).to have_been_requested
        end

        it "logs the creation" do
          create_a = stub_creation_for("a")
          create_b = stub_creation_for("b")
          create_c = stub_creation_for("c")

          subject.post_deploy

          expect(logger).to have_logged(
            "installing service auth token for 'service-name-a' (via 'service-provider-a')")

          expect(logger).to have_logged(
            "installing service auth token for 'service-name-b' (via 'service-provider-b')")

          expect(logger).to have_logged(
            "installing service auth token for 'service-name-c' (via 'service-provider-c')")
        end

        context "when a service is already registered" do
          it "swallows the error and continue" do
            create_a = stub_creation_for("a")
            create_b = stub_creation_taken_failure_for("b")
            create_c = stub_creation_for("c")

            subject.post_deploy

            expect(create_a).to have_been_requested
            expect(create_b).to have_been_requested
            expect(create_c).to have_been_requested
          end

          it "logs that it was already registered" do
            create_a = stub_creation_for("a")
            create_b = stub_creation_taken_failure_for("b")
            create_c = stub_creation_for("c")

            subject.post_deploy

            expect(logger).to have_logged("service auth token already installed")
          end
        end

        context "when an unknown error occurs" do
          it "bubbles it up" do
            create_a = stub_creation_for("a")
            create_b = stub_creation_unknown_failure_for("b")
            create_c = stub_creation_for("c")

            expect {
              subject.post_deploy
            }.to raise_error

            expect(create_a).to have_been_requested
            expect(create_b).to have_been_requested
            expect(create_c).to_not have_been_requested
          end
        end
      end
    end
  end
end
