# encoding: utf-8
# author: Dominik Richter

require_relative 'docker_run'
require_relative '../lib/inspec'

tests = ARGV
if tests.empty?
  puts 'Nothing to do.'
  exit 0
end

class DockerTester
  def initialize(tests)
    @tests = tests
    @docker = DockerRunner.new
  end

  def run
    puts ['Running tests:', @tests].flatten.join("\n- ")
    puts ''

    conf = RSpec.configuration
    reporter = conf.reporter
    results = nil

    # start reporting loop
    reporter.report(0) do |report|
      results = @docker.run_all do |name, container|
        status = test_container(container, report)
        status.all? ? nil : "Failed to run tests on #{name}"
      end
    end

    # check if we were successful
    failures = results.compact
    failures.each { |f| puts "\033[31;1m#{f}\033[0m\n\n" }
    failures.empty? or fail 'Test failures'
  end

  def test_container(container, report)
    puts "--> run test on docker #{container.id}"
    opts = { 'target' => "docker://#{container.id}" }
    runner = Inspec::Runner.new(opts)
    runner.add_tests(@tests)
    runner.tests.map { |g| g.run(report) }
  end
end

DockerTester.new(tests).run
