# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'functional/helper'
require 'jsonschema'

describe 'inspec check' do
  include FunctionalHelper

  describe 'inspec check with json formatter' do
    it 'can check a profile and produce valid JSON' do
      out = inspec('check ' + integration_test_path + ' --format json')
      out.exit_status.must_equal 0
      JSON.parse(out.stdout)
    end
  end

  describe 'inspec check with special characters in path' do
    it 'can check a profile with special characters in its path' do
      out = inspec('check ' + File.join(profile_path, '{{special-path}}'))
      out.exit_status.must_equal 0
    end
  end

  describe 'inspec check with skipping/failing a resource in FilterTable' do
    it 'can check a profile with special characters in its path' do
      out = inspec('check ' + File.join(profile_path, 'profile-with-resource-exceptions'))
      out.exit_status.must_equal 0
    end
  end
end
