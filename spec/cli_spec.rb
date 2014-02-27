require 'spec_helper'
require 'cf_deployer/cli'

module CfDeployer
  describe CLI do
    let(:cf_deploy) { double(CfDeploy) }
    let(:deploy_environment) { double(DeployEnvironment) }
    let(:argv) { %w(FAKE ARGV) }
    let(:logger) { double(Logger) }
    let(:options_parser) { double(OptionsParser, options: options, parse!: nil, validate!: nil) }
    let(:options) { double(OptionsParser::Options).as_null_object }

    it 'builds, parses, and validates an OptionsParser' do
      allow(CfDeploy).to receive(:build)
      expect(OptionsParser).to receive(:new).with(argv).and_return(options_parser)
      expect(options_parser).to receive(:parse!).with(no_args).ordered
      expect(options_parser).to receive(:validate!).with(no_args).ordered

      CLI.start(argv, logger) {}
    end

    it 'initializes and yields a CfDeploy object' do
      allow(OptionsParser).to receive(:new).and_return(options_parser)
      expect(CfDeploy).to receive(:build).with(options, logger).and_return(cf_deploy)

      expect { |b| described_class.start([], logger, &b) }.to yield_with_args(cf_deploy)
    end

    describe 'when an exception is raised' do
      before do
        allow(described_class).to receive(:exit)
        allow(logger).to receive(:log_exception)
        allow(CfDeploy).to receive(:build).and_return(cf_deploy)
        allow(OptionsParser).to receive(:new).and_return(options_parser)
      end

      it 'logs the exception' do
        expect(logger).to receive(:log_exception) do |e|
          expect(e.message).to eq('something bad!')
        end

        described_class.start([], logger) do
          raise 'something bad!'
        end
      end

      it 'exits with 1' do
        expect(described_class).to receive(:exit).with(1)

        described_class.start([], logger) do
          raise 'something bad!'
        end
      end
    end
  end
end