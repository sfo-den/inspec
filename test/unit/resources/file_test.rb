# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

describe Inspec::Resources::FileResource do
  let(:file) { stub(unix_mode_mask: 000, mode: 000) }
  it 'responds on Ubuntu' do
    resource = MockLoader.new(:ubuntu1404).load_resource('file', '/fakepath/fakefile')
    resource.stubs(:exist?).returns(true)
    resource.stubs(:mounted?).returns(true)
    resource.stubs(:source_path).returns('/fakepath/fakefile')
    resource.stubs(:file).returns(file)
    resource.stubs(:content).returns('content')
    resource.stubs(:mode).returns(000)
    resource.stubs(:suid).returns(true)
    resource.stubs(:sgid).returns(true)
    resource.stubs(:sticky).returns(true)
    resource.stubs(:file_permission_granted?).with('read', 'by_usergroup', 'by_specific_user').returns('test_result')
    resource.stubs(:file_permission_granted?).with('write', 'by_usergroup', 'by_specific_user').returns('test_result')
    resource.stubs(:file_permission_granted?).with('execute', 'by_usergroup', 'by_specific_user').returns('test_result')
    _(resource.content).must_equal 'content'
    _(resource.exist?).must_equal true
    _(resource.mounted?).must_equal true
    _(resource.to_s).must_equal 'File /fakepath/fakefile'
    _(resource.readable?('by_usergroup', 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('read', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
    _(resource.writable?('by_usergroup', 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('write', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
    _(resource.executable?('by_usergroup', 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('execute', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
    _(resource.suid).must_equal true
    _(resource.sgid).must_equal true
    _(resource.sticky).must_equal true
  end
  it 'responds on Windows' do
    resource = MockLoader.new(:windows).load_resource('file', 'C:/fakepath/fakefile')
    resource.stubs(:exist?).returns(true)
    resource.stubs(:mounted?).returns(true)
    resource.stubs(:content).returns('content')
    resource.stubs(:file_permission_granted?).with('read', 'by_usergroup', 'by_specific_user').returns('test_result')
    resource.stubs(:file_permission_granted?).with('write', 'by_usergroup', 'by_specific_user').returns('test_result')
    resource.stubs(:file_permission_granted?).with('execute', 'by_usergroup', 'by_specific_user').returns('test_result')
    resource.stubs(:file_permission_granted?).with('full-control', 'by_usergroup', 'by_specific_user').returns('test_result')
    _(resource.content).must_equal 'content'
    _(resource.exist?).must_equal true
    _(resource.mounted?).must_equal true
    _(resource.readable?('by_usergroup', 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('read', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
    _(resource.writable?('by_usergroup', 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('write', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
    _(resource.executable?('by_usergroup', 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('execute', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
    _(resource.allowed?('full-control', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal 'test_result'
  end
  it 'does not support Windows-style ACL on Ubuntu' do
    resource = MockLoader.new(:ubuntu1404).load_resource('file', '/fakepath/fakefile')
    resource.stubs(:exist?).returns(true)
    proc { resource.send('allowed?', 'full-control', { by: 'by_usergroup', by_user: 'by_specific_user' }) }.must_raise(RuntimeError)
    proc { resource.send('allowed?', 'modify', { by: 'by_usergroup', by_user: 'by_specific_user' }) }.must_raise(RuntimeError)
  end
  it 'does not support check by mask on Windows' do
    resource = MockLoader.new(:windows).load_resource('file', 'C:/fakepath/fakefile')
    resource.stubs(:exist?).returns(true)
    proc { resource.send('readable?', 'by_usergroup', nil) }.must_raise(RuntimeError)
    proc { resource.send('writable?', 'by_usergroup', nil) }.must_raise(RuntimeError)
    proc { resource.send('executable?', 'by_usergroup', nil) }.must_raise(RuntimeError)
  end
  it 'responds with errors on unsupported OS' do
    resource = MockLoader.new(:unsupported).load_resource('file', 'C:/fakepath/fakefile')
    resource.stubs(:exist?).returns(true)
    _(resource.exist?).must_equal true
    _(resource.readable?('by_usergroup', 'by_specific_user')).must_equal '`readable?` is not supported on your OS yet.'
    _(resource.writable?('by_usergroup', 'by_specific_user')).must_equal '`writable?` is not supported on your OS yet.'
    _(resource.executable?('by_usergroup', 'by_specific_user')).must_equal '`executable?` is not supported on your OS yet.'
    _(resource.allowed?('permission', by: 'by_usergroup', by_user: 'by_specific_user')).must_equal '`allowed?` is not supported on your OS yet.'
    proc { resource.send(:contain, nil) }.must_raise(RuntimeError)
  end
end
