require 'spec_helper'
require 'cf_deployer/release_manifest'

module CfDeployer
  describe ReleaseManifest do

    let(:manifest) { ReleaseManifest.new(content_hash) }

    describe '.load_file' do
      let(:content_hash) do
        { 'foo' => 'bar' }
      end

      it 'should construct a manifest using the hash in the yaml file' do
        ReleaseManifest.should_receive(:new).with(content_hash)

        Dir.mktmpdir('working_dir') do |working_dir|
          Dir.chdir(working_dir) do
            File.open('new_deployment.yml', 'w') do |io|
              io.write(content_hash.to_yaml)
            end

            ReleaseManifest.load_file('new_deployment.yml')
          end
        end
      end

      context 'file does not exist' do
        it 'gives a meaninful error' do
          expect {
            ReleaseManifest.load_file('/tmp/doesnotexist')
          }.to raise_error(/No such file/)
        end
      end
    end

    describe '#services_credentials' do
      context 'when the manifest does not contain services credentials' do
        let(:content_hash) do
          { 'properties' => nil }
        end

        it 'returns nil' do
          expect(manifest.services_credentials).to be_nil
        end
      end

      context 'when the manifest contains properties.uaa_client_auth_credentials' do
        let(:content_hash) do
          {
            'properties' => {
              'uaa_client_auth_credentials' => {
                'username' => 'services',
                'password' => 'letmein'
              }
            }
          }
        end
        it 'returns the username and password as an array' do
          expect(manifest.services_credentials).to eq(['services', 'letmein'])
        end
      end
    end

    describe '#service_tokens' do
      context 'when the manifest has no tokens' do
        let(:content_hash) do
          {'properties' => nil}
        end

        it 'returns an empty array' do
          expect(manifest.service_tokens).to eq([])
        end
      end

      context 'when the manifest has one appdirect token' do
        let(:content_hash) do
          {
            'properties' => {
              'appdirect_gateway' => {
                'services' => [{
                  'name' => 'cleardb',
                  'provider' => 'cleardb',
                  'ad_name' => 'mysql',
                  'ad_provider' => 'cleardb',
                  'tags' => ['mysql', 'relational'],
                  'auth_token' => 'mongodb_rocks_yo'
                }]
              }
            }
          }
        end

        it 'returns an array of hashes with the credentials' do
          expect(manifest.service_tokens).to eq([
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

      context 'when the manifest has one mysql token' do
        let(:content_hash) do
          {
            'jobs' => [{
              'name' => 'mysql_gateway',
              'properties' => {
                'mysql_gateway' => {
                  'token' => '2bits'
                }
              }
            }]
          }
        end

        it 'returns an array containing the token' do
          expect(manifest.service_tokens).to eq([
            {
              'name'        => 'mysql',
              'provider'    => 'core',
              'auth_token'  => '2bits'
            }
          ])
        end
      end

      context 'when the manifest has both appdirect and mysql tokens' do
        let(:manifest_file) { File.expand_path('../fixtures/appdirect-manifest.yml', __FILE__)}
        let(:manifest) { ReleaseManifest.load_file(manifest_file) }

        it 'returns an array of hashes with the credentials' do
          expect(manifest.service_tokens).to eq([
              {
                'name'        => 'cleardb',
                'provider'    => 'cleardb',
                'ad_name'     => 'mysql',
                'ad_provider' => 'cleardb',
                'tags'        => ['mysql', 'relational'],
                'auth_token'  => 'mongodb_rocks_yo'
              },
              {
                'name'        => 'dev3-happyfundb',
                'provider'    => 'happyfun',
                'ad_name'     => 'happyfun',
                'ad_provider' => 'happyfun',
                'tags'        => ['explosive', 'donottaunt'],
                'auth_token'  => 'secret'
              },
              {
                'name'        => 'mysql',
                'provider'    => 'core',
                'auth_token'  => '2bits'
              }
            ])
        end
      end
    end

    describe '#api_endpoint' do
      context 'and it does not contain the api endpoint' do
        let(:content_hash) do
          { 'properties' => nil }
        end

        it 'returns nil' do
          expect(manifest.api_endpoint).to be_nil
        end
      end

      context 'and the manifest contains properties.cc.srv_api_url' do
        let(:content_hash) do
          {
            'properties' => {
              'cc' => {
                'srv_api_uri' => 'http://api.example.com'
              }
            }
          }
        end

        it 'returns their username and password' do
          expect(manifest.api_endpoint).to eq('http://api.example.com')
        end
      end
    end
  end
end
