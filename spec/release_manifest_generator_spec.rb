require 'spec_helper'
require 'cf_deployer/release_manifest_generator'

module CfDeployer
  describe ReleaseManifestGenerator do
    let(:runner) { FakeCommandRunner.new }
    let(:release) { FakeReleaseRepo.new './repos/cf-release' }

    subject { described_class.new(runner, release, 'aws', 'new_deployment.yml') }

    around do |example|
      Dir.mktmpdir('working_dir') do |working_dir|
        Dir.chdir(working_dir, &example)
      end
    end

    before do
      allow(SpiffChecker).to receive(:spiff_present?).and_return(false)
    end

    describe '#generate!' do
      it 'installs spiff if not already present' do
        subject.generate!(['/woah', '/stub/files'])

        gospace = File.join(Dir.pwd, 'gospace')

        expect(runner).to have_executed_serially(
          ['go get -v github.com/cloudfoundry-incubator/spiff', environment: { 'GOPATH' => gospace }],
          [ './repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml',
            environment: { 'PATH' => "#{gospace}/bin:/usr/bin:/bin" }
          ]
        )
      end

      it 'does not install spiff if already present' do
        expect(SpiffChecker).to receive(:spiff_present?).and_return(true)

        subject.generate!(['/woah', '/stub/files'])

        gospace = File.join(Dir.pwd, 'gospace')

        expect(runner).to_not have_executed_serially(
          ['go get -v github.com/cloudfoundry-incubator/spiff', environment: { 'GOPATH' => gospace }],
          [ './repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml',
            environment: { 'PATH' => "#{gospace}/bin:/usr/bin:/bin" }
          ]
        )
      end

      it 'generates the deployment manifest' do
        subject.generate!(['/woah', '/stub/files'])

        expect(runner).to have_executed_serially(
          './repos/cf-release/generate_deployment_manifest aws /woah /stub/files > new_deployment.yml',
        )
      end

      it 'returns the full path to the generated manifest' do
        result = subject.generate!(['/woah', '/stub/files'])

        expect(result).to eq("#{Dir.pwd}/new_deployment.yml")
      end
    end

    describe 'overrides' do
      it 'includes overrides as the last stub_file' do
        real_temp_file = Tempfile.new('overrides')
        Tempfile.stub(:new).and_return(real_temp_file)
        real_temp_file.stub(:unlink)

        overrides = {'all' => {'your' => 'overrides'}, 'are' => 'present'}
        subject.overrides.merge!(overrides)

        subject.generate!(['/woah', '/stub/files'])

        expect(Tempfile).to have_received(:new).with('overrides')
        expect(YAML.load_file(real_temp_file)).to eq(overrides)

        expect(runner).to have_executed_serially(
                            "./repos/cf-release/generate_deployment_manifest aws /woah /stub/files #{real_temp_file.path} > new_deployment.yml",
                          )
        expect(real_temp_file).to have_received(:unlink)
      end
    end
  end
end
