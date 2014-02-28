require 'spec_helper'
require 'cf_deployer/cli'

module CfDeployer
  describe CLI do
    describe '#start' do
      let(:release) { double(Release) }
      let(:deploy_environment) { double(DeployEnvironment) }
      let(:argv) { %w(FAKE ARGV) }
      let(:logger) { double(Logger) }
      let(:options_parser) { double(OptionsParser, options: options, parse!: nil, validate!: nil) }
      let(:options) { double(OptionsParser::Options).as_null_object }

      it 'builds, parses, and validates an OptionsParser' do
        allow(Release).to receive(:build)
        expect(OptionsParser).to receive(:new).with(argv).and_return(options_parser)
        expect(options_parser).to receive(:parse!).with(no_args).ordered
        expect(options_parser).to receive(:validate!).with(no_args).ordered

        CLI.start(argv, [], logger)
      end

      it 'sends provided commands to a CfDeploy' do
        allow(OptionsParser).to receive(:new).and_return(options_parser)
        expect(Release).to receive(:build).with(options, logger).and_return(release)
        expect(release).to receive(:arbitrary_command)
        described_class.start([], [:arbitrary_command], logger)
      end

      describe 'when an exception is raised' do
        before do
          allow(described_class).to receive(:exit)
          allow(logger).to receive(:log_exception)
          allow(Release).to receive(:build).and_return(release)
          allow(OptionsParser).to receive(:new).and_return(options_parser)
        end

        it 'logs the exception' do
          allow(release).to receive(:doomed_command).and_raise('something bad!')
          expect(logger).to receive(:log_exception) do |e|
            expect(e.message).to eq('something bad!')
          end
          described_class.start([], [:doomed_command], logger)
        end

        it 'exits with 1' do
          allow(release).to receive(:doomed_command).and_raise('something bad!')
          expect(described_class).to receive(:exit).with(1)

          described_class.start([], [:doomed_command], logger)
        end
      end
    end
  end
end
