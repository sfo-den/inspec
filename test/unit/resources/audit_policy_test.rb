# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::AuditPolicy' do
  it 'check audit policy parsing' do
    resource = MockLoader.new(:windows).load_resource('audit_policy')
    _(resource.send('User Account Management')).must_equal 'Success'
  end
end
