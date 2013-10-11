require "spec_helper"
require "cf_deployer/manifest"

module CfDeployer
  describe ReleaseManifest do

    let(:manifest) { ReleaseManifest.new(content_hash) }

    describe '.load_file' do
      let(:content_hash) do
        { 'foo' => 'bar' }
      end

      it 'should construct a manifest using the hash in the yaml file' do
        ReleaseManifest.should_receive(:new).with(content_hash)

        Dir.mktmpdir("working_dir") do |working_dir|
          Dir.chdir(working_dir) do
            File.open("new_deployment.yml", "w") do |io|
              io.write(content_hash.to_yaml)
            end

            ReleaseManifest.load_file("new_deployment.yml")
          end
        end
      end

      context "file does not exist" do
        it 'gives a meaninful error' do
          expect {
            ReleaseManifest.load_file("/tmp/doesnotexist")
          }.to raise_error(/No such file/)
        end
      end
    end

    describe "#admin_credentials" do
      context "and the manifest does not contain scim information" do
        let(:content_hash) do
          { 'properties' => nil }
        end

        it "returns nil" do
          expect(manifest.admin_credentials).to be_nil
        end


      context "and the manifest contains properties.uaa.scim.users" do
        context "and there is an admin user" do
          let(:content_hash) do
            {
              'properties' => {
                'uaa' => {
                  'scim' => {
                    'users' => ['admin|secret|...']
                  }
                }
              }
            }
          end
          it "returns their username and password" do
            expect(manifest.admin_credentials).to eq(["admin", "secret"])
          end
        end

          context "and there is no admin user" do
            let(:content_hash) do
              {
                'properties' => {
                  'uaa' => {
                    'scim' => {
                      'users' => ['non-admin|secret|...']
                    }
                  }
                }
              }
            end

            it "returns nil" do
              expect(manifest.admin_credentials).to be_nil
            end
          end
        end
      end
    end

    describe "#appdirect_tokens" do
      context "the manifest does not contain the api endpoint" do
        let(:content_hash) do
          {'properties' => nil}
        end

        it "returns nil" do
          expect(manifest.appdirect_tokens).to be_nil
        end
      end

      context "the manifest contains properties.appdirect_gateway.services" do
        let(:manifest_file) { File.expand_path('../fixtures/appdirect-manifest.yml', __FILE__)}
        let(:manifest) { ReleaseManifest.load_file(manifest_file) }

        it "returns an array of hashes with the credentials" do
          expect(manifest.appdirect_tokens).to eq([
              {
                'name'        => 'cleardb',
                'provider'    => 'cleardb',
                'ad_name'     => 'mysql',
                'ad_provider' => 'cleardb',
                'tags'        => ['mysql', 'relational'],
                'auth_token'  => 'mongodb_rocks_yo'
              }
            ])
        end
      end
    end

    describe "#mysql_token" do
      context "and the manifest contains jobs.properties.mysql_gateway.token" do
        let(:manifest_file) { File.expand_path('../fixtures/appdirect-manifest.yml', __FILE__)}
        let(:manifest) { ReleaseManifest.load_file(manifest_file) }

        it "returns an array containing the token" do
          expect(manifest.mysql_token).to eq([
                                              {
                                                'name'        => 'mysql',
                                                'provider'    => 'core',
                                                'auth_token'  => '2bits'
                                              }
                                            ])
        end
      end

      context "and the manifest does not contain jobs.properties.mysql_gateway.token" do
        let(:content_hash) do
          {
            'jobs' => [
              {'name' => 'api'}
            ]
          }
        end

        it "should return an empty array" do
          expect(manifest.mysql_token).to eq([])
        end
      end
    end

    describe "#api_endpoint" do
      context "and it does not contain the api endpoint" do
        let(:content_hash) do
          { 'properties' => nil }
        end

        it "returns nil" do
          expect(manifest.api_endpoint).to be_nil
        end
      end

      context "and the manifest contains properties.cc.srv_api_url" do
        let(:content_hash) do
          {
            'properties' => {
              'cc' => {
                'srv_api_uri' => 'http://api.example.com'
              }
            }
          }
        end

        it "returns their username and password" do
          expect(manifest.api_endpoint).to eq("http://api.example.com")
        end
      end
    end
  end
end
