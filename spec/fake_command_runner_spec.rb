require 'spec_helper'

describe 'the fake command runner' do
  subject(:runner) { FakeCommandRunner.new }
  it 'can match a command on its own' do
    runner.run!('touch /foo')
    expect(runner).to have_executed_serially('touch /foo')
  end

  it 'can match a command that has options' do
    runner.run!('touch /foo', shell: 'sh')
    expect(runner).to have_executed_serially(['touch /foo', shell: 'sh'])
  end

  it 'matches the command with options even when the options are not passed to the matcher' do
    runner.run!('touch /foo', shell: 'sh')
    expect(runner).to have_executed_serially('touch /foo')
  end

  it 'does not match if the expected command is different from the command that was run' do
    runner.run!('bad idea')
    expect(runner).to_not have_executed_serially('good idea')
  end

  it 'does not match if the expected command options are different from the command that was run' do
    runner.run!('good idea', bad: 'friends')
    expect(runner).to_not have_executed_serially('good idea', great: 'friends')
  end

  it 'does not match if expected command options but none were present' do
    runner.run!('good idea')
    expect(runner).to_not have_executed_serially('good idea', great: 'friends')
  end

  it 'can match two commands serially' do
    runner.run!('tortoise')
    runner.run!('hare')
    expect(runner).to have_executed_serially('tortoise', 'hare')
  end

  it 'does not match if any of the commands do not match' do
    runner.run!('tortoise')
    runner.run!('hare')
    expect(runner).to_not have_executed_serially('tortoise', 'rabbit')
  end

  it 'matches multiple commands with options' do
    runner.run!('tortoise', type: 'reptile')
    runner.run!('hare', type: 'mammal')
    expect(runner).to have_executed_serially(['tortoise', type: 'reptile'], ['hare', type: 'mammal'])
    expect(runner).to_not have_executed_serially(['tortoise', type: 'mammal'], ['hare', type: 'reptile'])
  end

  it 'matches if the expected commands are not at the beginning of the actual command list' do
    runner.run!('setup')
    runner.run!('tortoise')
    runner.run!('hare')
    expect(runner).to have_executed_serially('tortoise', 'hare')
  end

  it 'matches if the first expected command is run twice, but the second is not run after the first instance' do
    runner.run!('setup')
    runner.run!('tortoise')
    runner.run!('box turtle')
    runner.run!('tortoise')
    runner.run!('hare')
    expect(runner).to have_executed_serially('tortoise', 'hare')
  end

  it 'does not match if the number of expected commands is greater than actual' do
    runner.run!('tortoise')
    expect(runner).not_to have_executed_serially('tortoise', 'hare')
  end

  it 'matches if the number of expected commands is less than actual' do
    runner.run!('tortoise')
    runner.run!('hare')
    expect(runner).to have_executed_serially('tortoise')
  end

  it 'does not match if there are gaps between expected commands' do
    runner.run!('tortoise')
    runner.run!('vagabond')
    runner.run!('hare')
    expect(runner).to_not have_executed_serially('tortoise', 'hare')
  end
end
