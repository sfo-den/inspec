# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::KernelParameter' do
  it 'verify kernel_parameter parsing' do
    resource = load_resource('kernel_parameter', 'net.ipv4.conf.all.forwarding')
    _(resource.value).must_equal 1
  end
end
