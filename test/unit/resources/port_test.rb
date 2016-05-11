# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Port' do
  it 'verify port on Ubuntu 14.04' do
    resource = MockLoader.new(:ubuntu1404).load_resource('port', 22)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal %w{ tcp tcp6 }
    _(resource.pids).must_equal [1]
    _(resource.processes).must_equal ['sshd']
    _(resource.addresses).must_equal ["0.0.0.0", "::"]
  end

  it 'verify UDP port on Ubuntu 14.04' do
    resource = MockLoader.new(:ubuntu1404).load_resource('port', 111)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal %w{ udp }
    _(resource.pids).must_equal [545]
    _(resource.processes).must_equal ['rpcbind']
    _(resource.addresses).must_equal ["0.0.0.0"]
  end

  it 'verify port on MacOs x' do
    resource = MockLoader.new(:osx104).load_resource('port', 2022)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal ['tcp']
    _(resource.processes).must_equal ['VBoxHeadl']
    _(resource.addresses).must_equal ["127.0.0.1"]
  end

  it 'verify port on Windows' do
    resource = MockLoader.new(:windows).load_resource('port', 135)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal ['tcp']
    _(resource.processes).must_equal []
    _(resource.addresses).must_equal ["::", "192.168.10.157"]
  end

  it 'verify port on FreeBSD' do
    resource = MockLoader.new(:freebsd10).load_resource('port', 22)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal %w{ tcp6 tcp }
    _(resource.pids).must_equal [668]
    _(resource.processes).must_equal ['sshd']
    _(resource.addresses).must_equal ["0:0:0:0:0:0:0:0", "0.0.0.0"]
  end

  it 'verify port on wrlinux' do
    resource = MockLoader.new(:wrlinux).load_resource('port', 22)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal %w{ tcp tcp6 }
    _(resource.processes).must_equal ['sshd']
    _(resource.addresses).must_equal ["0.0.0.0", "::"]
  end

  it 'verify running on undefined' do
    resource = MockLoader.new(:undefined).load_resource('port', 22)
    _(resource.listening?).must_equal false
    _(resource.protocols).must_equal []
    _(resource.pids).must_equal []
    _(resource.processes).must_equal []
    _(resource.addresses).must_equal []
  end

  it 'verify port and interface on Ubuntu 14.04' do
    resource = MockLoader.new(:ubuntu1404).load_resource('port', '0.0.0.0', 22)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal %w{ tcp }
    _(resource.pids).must_equal [1]
    _(resource.processes).must_equal ['sshd']
    _(resource.addresses).must_equal ["0.0.0.0"]
  end

  it 'verify not listening port on interface on Ubuntu 14.04' do
    resource = MockLoader.new(:ubuntu1404).load_resource('port', '127.0.0.1', 22)
    _(resource.listening?).must_equal false
    _(resource.addresses).must_equal []
  end

  it 'verify port on Solaris 10' do
    resource = MockLoader.new(:solaris10).load_resource('port', 22)
    _(resource.listening?).must_equal true
    _(resource.addresses).must_equal ["0.0.0.0"]
  end

  it 'verify port on Solaris 11' do
    resource = MockLoader.new(:solaris11).load_resource('port', 22)
    _(resource.listening?).must_equal true
    _(resource.addresses).must_equal ["0.0.0.0"]
  end

  it 'verify port on hpux' do
    resource = MockLoader.new(:hpux).load_resource('port', 22)
    _(resource.listening?).must_equal true
    _(resource.protocols).must_equal %w{ tcp tcp6 }
    _(resource.addresses).must_equal ["0.0.0.0", "0:0:0:0:0:0:0:0" ]
  end

  it 'verify not listening port on hpux' do
    resource = MockLoader.new(:hpux).load_resource('port', 23)
    _(resource.listening?).must_equal false
    _(resource.protocols).must_equal []
    _(resource.addresses).must_equal []
  end
end
