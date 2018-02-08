# encoding: utf-8

require 'helper'

describe Inspec::Reporters::Json do
  let(:path) { File.expand_path(File.dirname(__FILE__)) }
  let(:report) do
    data = JSON.parse(File.read(path + '/../mock/reporters/run_data.json'), symbolize_names: true)
    Inspec::Reporters::Json.new({ run_data: data })
  end
  let(:profile) { report.run_data[:profiles].first }
  let(:control) { profile[:controls].first }

  describe '#render' do
    it 'confirm render output' do
      cli_output = File.read(path + '/../mock/reporters/json_output')
      report.render
      report.rendered_output.must_equal cli_output
    end
  end

  describe '#platform' do
    it 'confirm platform output' do
      hash = { name: 'mac_os_x', release: '17.2.0' }
      report.send(:platform).must_equal hash
    end
  end

  describe '#controls' do
    it 'confirm control output' do
      hash = {
        status: 'passed',
        start_time: '2018-01-05 11:43:04 -0500',
        run_time: 0.002058,
        code_desc: 'File /tmp should be directory',
      }
      controls = report.send(:controls)
      controls.first.must_equal hash
      controls.count.must_equal 4
    end

    it 'confirm control output with optional' do
      report.run_data[:controls].first[:resource] = 'File'
      report.run_data[:controls].first[:skip_message] = 'skipping'
      hash = {
        status: 'passed',
        start_time: '2018-01-05 11:43:04 -0500',
        run_time: 0.002058,
        code_desc: 'File /tmp should be directory',
        resource: 'File',
        skip_message: 'skipping',
      }
      controls = report.send(:controls)
      controls.first.must_equal hash
      controls.count.must_equal 4
    end
  end

  describe '#profile_results' do
    it 'confirm profile_results output' do
      hash = {
        status: 'passed',
        code_desc: 'File /tmp should be directory',
        run_time: 0.002058,
        start_time: '2018-01-05 11:43:04 -0500',
      }
      result = report.send(:profile_results, control)
      result.first.must_equal hash
    end

    it 'confirm profile_result with optional' do
      control[:results].first[:resource] = 'File'
      control[:results].first[:skip_message] = 'skipping'
      hash = {
        status: 'passed',
        code_desc: 'File /tmp should be directory',
        run_time: 0.002058,
        start_time: '2018-01-05 11:43:04 -0500',
        resource: 'File',
        skip_message: 'skipping',
      }
      result = report.send(:profile_results, control)
      result.first.must_equal hash
    end
  end

  describe '#profile_controls' do
    it 'confirm profile_results output' do
      hash = {
        id: '(generated from example.rb:7 871cd54043069c5c4f6e382fd5627830)',
        title: nil,
        desc: nil,
        impact: 0.5,
        refs: [],
        tags: {},
        code: '',
        source_location: {
          line: 89,
          ref: '/Users/jquick/Chef/inspec/lib/inspec/control_eval_context.rb',
        },
      }
      control = report.send(:profile_controls, profile).first
      control.delete(:results)
      control.must_equal hash
    end
  end

  describe '#profile_groups' do
    it 'confirm profile_groups output' do
      hash = {
        id: 'controls/example.rb',
        controls: [
          '(generated from example.rb:7 871cd54043069c5c4f6e382fd5627830)',
          'tmp-1.0',
          '(generated from example.rb:21 2ff474c5357e7070f4c3efa932032dcb)',
        ],
        title: 'sample section',
      }
      group = report.send(:profile_groups, profile)
      group.first.must_equal hash
    end
  end

  describe '#profiles' do
    it 'confirm profile_groups output' do
      hash = {
        name: 'long_commands',
        version: '0.1.0',
        sha256: '4f816f8cf18f165f05f1cf20936aaad06a15287de3f578891197647ca05c7df4',
        title: 'InSpec Profile',
        maintainer: 'The Authors',
        summary: 'An InSpec Compliance Profile',
        license: 'Apache-2.0',
        copyright: 'The Authors',
        copyright_email: 'you@example.com',
        supports: [
          { 'os-family': 'bds' },
          {
            'os-name': 'mac_os_x',
            release: '17.*',
          },
        ],
        attributes: [],
      }
      profile = report.send(:profiles).first
      profile.delete(:groups)
      profile.delete(:controls)
      profile.must_equal hash
    end
  end
end
