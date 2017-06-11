# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Interface' do

  # ubuntu 14.04
  it 'verify interface on ubuntu' do
    resource = MockLoader.new(:ubuntu1404).load_resource('interface', 'eth0')
    _(resource.exists?).must_equal true
    _(resource.up?).must_equal true
    _(resource.speed).must_equal 10000
  end

  it 'verify invalid interface on ubuntu' do
    resource = MockLoader.new(:ubuntu1404).load_resource('interface', 'eth1')
    _(resource.exists?).must_equal false
    _(resource.up?).must_equal false
    _(resource.speed).must_be_nil
  end

  it 'verify interface on windows' do
    resource = MockLoader.new(:windows).load_resource('interface', 'ethernet0')
    _(resource.exists?).must_equal true
    _(resource.up?).must_equal false
    _(resource.speed).must_equal 0
  end

  it 'verify interface on windows' do
    resource = MockLoader.new(:windows).load_resource('interface', 'vEthernet (Intel(R) PRO 1000 MT Network Connection - Virtual Switch)')
    _(resource.exists?).must_equal true
    _(resource.up?).must_equal true
    _(resource.speed).must_equal 10000000
  end

  it 'verify invalid interface on windows' do
    resource = MockLoader.new(:windows).load_resource('interface', 'eth1')
    _(resource.exists?).must_equal false
    _(resource.up?).must_equal false
    _(resource.speed).must_be_nil
  end

  # undefined
  it 'verify interface on unsupported os' do
    resource = MockLoader.new(:undefined).load_resource('interface', 'eth0')
    _(resource.exists?).must_equal false
    _(resource.up?).must_equal false
    _(resource.speed).must_be_nil
  end

end
