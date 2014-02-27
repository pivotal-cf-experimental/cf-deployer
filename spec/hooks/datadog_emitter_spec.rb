require 'base64'
require 'json'

require 'spec_helper'
require 'cf_deployer/hooks/datadog_emitter'

module CfDeployer
  describe DatadogEmitter do
    let(:generated_manifest) { Tempfile.new('generated-manifest.yml') }

    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }

    let(:release) { FakeReleaseRepo.new './repos/cf-release' }
    let(:manifest) { ReleaseManifest.new runner, release, 'doesnt-matter', generated_manifest.path }

    let(:dogapi_client) { double :dogapi_client }

    subject { described_class.new(logger, dogapi_client, 'some-deployment') }

    describe '#pre_deploy' do
      it 'emits a start_deploy start event for the deployment' do
        expect(dogapi_client).to receive(:emit_event).with { |event|
          expect(event.msg_text).to eq('start_deploy')
          expect(event.tags).to include('deployment:some-deployment')
        }

        subject.pre_deploy
      end

      it "logs that it's emitting a start_deploy event" do
        dogapi_client.stub(:emit_event)

        subject.pre_deploy

        expect(logger).to have_logged(/emitting start_deploy/)
      end
    end

    describe '#post_deploy' do
      it 'emits a end_deploy stop event for the deployment' do
        expect(dogapi_client).to receive(:emit_event).with { |event|
          expect(event.msg_text).to eq('end_deploy')
          expect(event.tags).to include('deployment:some-deployment')
        }

        subject.post_deploy
      end

      it "logs that it's emitting an end_deploy event" do
        dogapi_client.stub(:emit_event)

        subject.post_deploy

        expect(logger).to have_logged(/emitting end_deploy/)
      end
    end
  end
end
