require 'bundler'

$:.unshift(File.expand_path("../../lib", __FILE__))

Bundler.require
require 'cf_deploy'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end
end

def capture_std(&block)
  orig_stdout, orig_stderr, orig_stdin = $stdout, $stderr, $stdin
  new_stdout, new_stderr, new_stdin = StringIO.new, StringIO.new, StringIO.new
  $stdout, $stderr, $stdin = new_stdout, new_stderr, new_stdin
  block.yield new_stdout.string, new_stderr.string, new_stdin
ensure
  $stdout, $stderr, $stdin = orig_stdout, orig_stderr, orig_stdin
end